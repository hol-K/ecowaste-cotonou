@echo off
echo ========================================
echo CREATION DE LA STRUCTURE ECOWASTE COTONOU
echo ========================================
echo.

REM Création des dossiers core
echo [1/4] Creation des dossiers CORE...
mkdir lib\core\constants 2>nul
mkdir lib\core\theme 2>nul
mkdir lib\core\utils 2>nul
mkdir lib\core\widgets 2>nul

REM Création des dossiers data
echo [2/4] Creation des dossiers DATA...
mkdir lib\data\models 2>nul
mkdir lib\data\repositories 2>nul
mkdir lib\data\services 2>nul

REM Création des dossiers presentation
echo [3/4] Creation des dossiers PRESENTATION...
mkdir lib\presentation\providers 2>nul
mkdir lib\presentation\screens\splash 2>nul
mkdir lib\presentation\screens\onboarding 2>nul
mkdir lib\presentation\screens\home 2>nul
mkdir lib\presentation\screens\calendar 2>nul
mkdir lib\presentation\screens\guide 2>nul
mkdir lib\presentation\screens\map 2>nul
mkdir lib\presentation\screens\profile 2>nul
mkdir lib\presentation\widgets\calendar_widgets 2>nul
mkdir lib\presentation\widgets\guide_widgets 2>nul
mkdir lib\presentation\widgets\map_widgets 2>nul

REM Création des dossiers assets et tests
echo [4/4] Creation des dossiers ASSETS et TESTS...
mkdir assets\images 2>nul
mkdir assets\icons 2>nul
mkdir assets\animations 2>nul
mkdir test\unit 2>nul
mkdir test\widget 2>nul
mkdir test\integration 2>nul

echo.
echo ========================================
echo STRUCTURE CREEE AVEC SUCCES !
echo ========================================
echo.
echo Dossiers crees :
echo - lib\core\ (constants, theme, utils, widgets)
echo - lib\data\ (models, repositories, services)
echo - lib\presentation\ (providers, screens, widgets)
echo - assets\ (images, icons, animations)
echo - test\ (unit, widget, integration)
echo.
echo Vous pouvez maintenant commencer a coder !
echo.
pause