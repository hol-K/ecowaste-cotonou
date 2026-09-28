-- =====================================================================
-- EcoWaste Cotonou : schéma initial Supabase (remplace Firestore)
-- À exécuter une seule fois : Supabase > SQL Editor > New query > Run
-- =====================================================================

-- ---------------------------------------------------------------------
-- Types énumérés (mêmes valeurs que les enums Dart WasteType et
-- RecyclingCategory : une valeur inconnue est refusée par la base)
-- ---------------------------------------------------------------------
create type public.waste_type as enum (
  'general', 'recyclable', 'glass', 'organic', 'dangerous', 'electronic'
);

create type public.recycling_category as enum (
  'plastic', 'paper', 'glass', 'metal', 'organic', 'dangerous', 'electronic'
);

-- ---------------------------------------------------------------------
-- Profils utilisateurs (1 ligne par compte Supabase Auth)
-- ---------------------------------------------------------------------
create table public.profiles (
  id                    uuid primary key references auth.users (id) on delete cascade,
  name                  text,
  email                 text,
  phone                 text,
  photo_url             text,
  district              text not null default 'Akpakpa',
  statistics            jsonb not null default '{}'::jsonb,
  notification_settings jsonb not null default '{}'::jsonb,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

-- Le profil est créé par la base à l'inscription, à partir des métadonnées
-- (name, district) envoyées par l'app : plus de course entre la création
-- du compte et l'écriture du profil.
create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, email, name, district)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data ->> 'name',
    coalesce(new.raw_user_meta_data ->> 'district', 'Akpakpa')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_touch_updated_at
  before update on public.profiles
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------
-- Calendrier des collectes
-- ---------------------------------------------------------------------
create table public.collection_schedules (
  id                 uuid primary key default gen_random_uuid(),
  district           text not null,
  waste_type         public.waste_type not null,
  collection_date    date not null,
  collection_time    text not null default '',
  instructions       text not null default '',
  is_recurring       boolean not null default false,
  recurrence_pattern text,
  created_at         timestamptz not null default now()
);

-- Requête principale : collectes d'un quartier sur une période
create index collection_schedules_district_date_idx
  on public.collection_schedules (district, collection_date);

-- ---------------------------------------------------------------------
-- Guide de tri
-- ---------------------------------------------------------------------
create table public.recycling_guide_items (
  id                   uuid primary key default gen_random_uuid(),
  name                 text not null,
  category             public.recycling_category not null,
  waste_type           public.waste_type not null,
  image_url            text not null default '',
  description          text not null default '',
  instructions         text[] not null default '{}',
  environmental_impact text not null default '',
  keywords             text[] not null default '{}',
  alternatives         text[],
  view_count           integer not null default 0,
  created_at           timestamptz not null default now()
);

create index recycling_guide_items_name_idx on public.recycling_guide_items (name);

-- ---------------------------------------------------------------------
-- Points de collecte
-- ---------------------------------------------------------------------
create table public.collection_points (
  id                   uuid primary key default gen_random_uuid(),
  name                 text not null,
  latitude             double precision not null,
  longitude            double precision not null,
  address              text not null default '',
  accepted_waste_types public.waste_type[] not null default '{}',
  opening_hours        text not null default '',
  phone                text,
  image_url            text,
  description          text,
  is_public            boolean not null default true,
  rating               numeric(2, 1) check (rating between 0 and 5),
  created_at           timestamptz not null default now()
);

create index collection_points_name_idx on public.collection_points (name);

-- ---------------------------------------------------------------------
-- Sécurité (Row Level Security)
-- Lecture publique du contenu ; chaque utilisateur ne voit et ne modifie
-- que son propre profil. Aucune écriture du contenu depuis l'app :
-- plannings, guide et points se gèrent depuis le tableau de bord.
-- ---------------------------------------------------------------------
alter table public.profiles              enable row level security;
alter table public.collection_schedules  enable row level security;
alter table public.recycling_guide_items enable row level security;
alter table public.collection_points     enable row level security;

create policy "Profil lisible par son propriétaire"
  on public.profiles for select to authenticated
  using ((select auth.uid()) = id);

create policy "Profil modifiable par son propriétaire"
  on public.profiles for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

create policy "Plannings lisibles par tous"
  on public.collection_schedules for select to anon, authenticated
  using (true);

create policy "Guide lisible par tous"
  on public.recycling_guide_items for select to anon, authenticated
  using (true);

create policy "Points publics lisibles par tous"
  on public.collection_points for select to anon, authenticated
  using (is_public);

-- ---------------------------------------------------------------------
-- Fonctions appelables depuis l'app (RPC)
-- ---------------------------------------------------------------------

-- Compteur de vues du guide, sans ouvrir l'écriture sur la table
create function public.increment_guide_view(item_id uuid)
returns void
language sql
security definer set search_path = ''
as $$
  update public.recycling_guide_items
  set view_count = view_count + 1
  where id = item_id;
$$;

grant execute on function public.increment_guide_view(uuid) to anon, authenticated;

-- Suppression de son propre compte (le profil suit via ON DELETE CASCADE)
create function public.delete_own_account()
returns void
language plpgsql
security definer set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Non authentifié';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke execute on function public.delete_own_account() from public, anon;
grant execute on function public.delete_own_account() to authenticated;

-- ---------------------------------------------------------------------
-- Temps réel (utilisé par .stream() dans l'app)
-- ---------------------------------------------------------------------
alter publication supabase_realtime
  add table public.profiles, public.recycling_guide_items, public.collection_points;

-- =====================================================================
-- DONNÉES DE DÉMONSTRATION (reprises de FirebaseSeeder)
-- =====================================================================

-- Plannings : 12 mois à partir du mois en cours, pour les 12 quartiers
-- de l'app. Ordures ménagères lundi et jeudi, recyclables mardi,
-- verre le 1er et le 15.
insert into public.collection_schedules
  (district, waste_type, collection_date, collection_time, instructions, is_recurring, recurrence_pattern)
select
  q.district,
  s.waste_type::public.waste_type,
  g.jour::date,
  s.horaire,
  s.instructions,
  true,
  s.pattern
from unnest(array[
  'Akpakpa', 'Cadjèhoun', 'Fidjrossè', 'Godomey', 'Agla', 'Vossa',
  'Gbégamey', 'Houéyiho', 'Jonquet', 'Enagnon', 'Saint-Michel', 'Zongo'
]) as q(district)
cross join generate_series(
  date_trunc('month', current_date),
  date_trunc('month', current_date) + interval '12 months' - interval '1 day',
  interval '1 day'
) as g(jour)
cross join (values
  ('general',    '06:00 - 10:00', 'Sortez vos poubelles la veille au soir. Fermez bien les sacs.', 'weekly'),
  ('recyclable', '06:00 - 10:00', 'Triez plastique, papier et carton. Rincez les contenants.',     'weekly'),
  ('glass',      '08:00 - 12:00', 'Vider et rincer les bouteilles. Retirer les bouchons.',          'monthly')
) as s(waste_type, horaire, instructions, pattern)
where (s.waste_type = 'general'    and extract(isodow from g.jour) in (1, 4))
   or (s.waste_type = 'recyclable' and extract(isodow from g.jour) = 2)
   or (s.waste_type = 'glass'      and extract(day from g.jour) in (1, 15));

-- Guide de tri
insert into public.recycling_guide_items
  (name, category, waste_type, description, instructions, environmental_impact, keywords, alternatives)
values
  ('Bouteille en plastique', 'plastic', 'recyclable',
   'Bouteilles d''eau, de soda ou de jus en plastique PET',
   array['Vider complètement', 'Rincer à l''eau claire', 'Enlever le bouchon', 'Écraser pour gagner de la place'],
   '1 tonne de plastique recyclé = 830 litres de pétrole économisés',
   array['bouteille', 'plastique', 'pet', 'eau', 'soda'],
   array['Utiliser une gourde réutilisable', 'Acheter en vrac']),

  ('Sachet plastique', 'plastic', 'general',
   'Sacs plastiques fins pour courses',
   array['Jeter dans les ordures ménagères', 'Ne pas mettre dans les recyclables'],
   'Un sac plastique met 400 ans à se dégrader',
   array['sac', 'sachet', 'plastique', 'courses'],
   array['Utiliser des sacs réutilisables en tissu', 'Privilégier les paniers']),

  ('Carton d''emballage', 'paper', 'recyclable',
   'Boîtes en carton, emballages',
   array['Aplatir les cartons', 'Retirer le scotch et les agrafes', 'Garder au sec'],
   '1 tonne de carton recyclé = 2,5 tonnes de bois sauvées',
   array['carton', 'boite', 'emballage'], null),

  ('Journal / Magazine', 'paper', 'recyclable',
   'Journaux, magazines, prospectus',
   array['Retirer les films plastiques', 'Ne pas froisser', 'Garder au sec'],
   '1 tonne de papier recyclé = 17 arbres sauvés',
   array['journal', 'magazine', 'papier', 'prospectus'], null),

  ('Bouteille en verre', 'glass', 'glass',
   'Bouteilles de vin, bière, jus',
   array['Vider complètement', 'Rincer rapidement', 'Retirer le bouchon', 'Ne pas casser'],
   'Le verre se recycle à l''infini sans perte de qualité',
   array['verre', 'bouteille', 'vin', 'biere'], null),

  ('Bocal en verre', 'glass', 'glass',
   'Pots de confiture, bocaux de conservation',
   array['Vider et rincer', 'Retirer le couvercle métallique', 'Ne pas casser'],
   'Recycler un bocal économise l''énergie équivalente à 4h d''ampoule',
   array['bocal', 'pot', 'verre', 'confiture'], null),

  ('Canette aluminium', 'metal', 'recyclable',
   'Canettes de soda, bière',
   array['Vider complètement', 'Rincer', 'Écraser'],
   'Recycler l''aluminium économise 95% de l''énergie nécessaire',
   array['canette', 'aluminium', 'soda', 'biere'], null),

  ('Boîte de conserve', 'metal', 'recyclable',
   'Conserves métalliques',
   array['Vider et rincer', 'Enlever l''étiquette', 'Écraser si possible'],
   '1 tonne d''acier recyclé = 1 tonne de minerai économisée',
   array['conserve', 'boite', 'metal', 'acier'], null),

  ('Épluchures de légumes', 'organic', 'organic',
   'Restes de fruits et légumes',
   array['Mettre dans un composteur', 'Ou dans les ordures ménagères'],
   'Le compost enrichit le sol naturellement',
   array['epluchure', 'legume', 'fruit', 'compost'], null),

  ('Marc de café', 'organic', 'organic',
   'Résidus de café moulu',
   array['Excellent pour le compost', 'Peut servir d''engrais'],
   'Le marc de café enrichit le sol en azote',
   array['cafe', 'marc', 'compost'], null),

  ('Pile usagée', 'dangerous', 'dangerous',
   'Piles alcalines, rechargeables',
   array['Ne JAMAIS jeter avec les ordures', 'Apporter dans un point de collecte spécialisé', 'Conserver dans l''emballage d''origine'],
   '1 pile jetée pollue 1m³ de terre pendant 50 ans',
   array['pile', 'batterie', 'dangereux'], null),

  ('Ampoule', 'dangerous', 'dangerous',
   'Ampoules basse consommation, LED',
   array['Ne pas jeter avec le verre', 'Apporter en déchetterie', 'Ne pas casser'],
   'Les ampoules contiennent du mercure toxique',
   array['ampoule', 'led', 'lumiere'], null),

  ('Téléphone portable', 'electronic', 'electronic',
   'Smartphones, téléphones',
   array['Supprimer toutes les données', 'Retirer la carte SIM', 'Apporter dans un point DEEE'],
   '80% des matériaux d''un téléphone sont recyclables',
   array['telephone', 'smartphone', 'portable', 'mobile'], null),

  ('Ordinateur', 'electronic', 'electronic',
   'PC, ordinateurs portables',
   array['Effacer toutes les données', 'Apporter en déchetterie', 'Possibilité de don si fonctionnel'],
   'Recycler 1 ordinateur récupère métaux précieux et plastiques',
   array['ordinateur', 'pc', 'laptop'], null);

-- Points de collecte
insert into public.collection_points
  (name, latitude, longitude, address, accepted_waste_types, opening_hours, phone, description, rating)
values
  ('Déchetterie Municipale d''Akpakpa', 6.3667, 2.4333,
   'Route de Porto-Novo, Akpakpa, Cotonou',
   array['general', 'recyclable', 'glass', 'organic', 'dangerous', 'electronic']::public.waste_type[],
   'Lundi - Samedi: 08:00 - 18:00', '+229 21 30 00 00',
   'Déchetterie principale acceptant tous types de déchets', 4.5),

  ('Point de Collecte Recyclable Cadjèhoun', 6.3703, 2.3912,
   'Avenue Steinmetz, Cadjèhoun, Cotonou',
   array['recyclable', 'glass']::public.waste_type[],
   'Lundi - Vendredi: 09:00 - 17:00', '+229 21 31 00 00',
   'Collecte de recyclables et verre uniquement', 4.0),

  ('Centre de Tri de Godomey', 6.4000, 2.3500,
   'Route de Ouidah, Godomey, Cotonou',
   array['general', 'recyclable', 'glass']::public.waste_type[],
   'Lundi - Samedi: 07:00 - 19:00', '+229 21 32 00 00',
   'Centre de tri principal de la zone ouest', 4.2),

  ('Point de Collecte DEEE Fidjrossè', 6.3833, 2.4167,
   'Boulevard de la Marina, Fidjrossè, Cotonou',
   array['electronic', 'dangerous']::public.waste_type[],
   'Mardi - Samedi: 10:00 - 16:00', '+229 21 33 00 00',
   'Spécialisé dans les déchets électroniques et dangereux', 4.8),

  ('Recyclerie Communautaire de Vossa', 6.3500, 2.4000,
   'Quartier Vossa, Cotonou',
   array['recyclable', 'glass', 'organic']::public.waste_type[],
   'Lundi - Vendredi: 08:00 - 16:00', '+229 21 34 00 00',
   'Initiative communautaire de recyclage', 4.3),

  ('Déchetterie d''Agla', 6.3900, 2.3700,
   'Quartier Agla, Cotonou',
   array['general', 'recyclable']::public.waste_type[],
   'Lundi - Samedi: 08:00 - 17:00', '+229 21 35 00 00',
   'Point de collecte de proximité', 3.8);
