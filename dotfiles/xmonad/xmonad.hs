{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeSynonymInstances #-}
{-# OPTIONS_GHC -fno-warn-missing-signatures #-}

import Data.Char
import Data.Functor

import           XMonad
import qualified XMonad.StackSet               as W
import           XMonad.Prompt
import           XMonad.Prompt.ConfirmPrompt    ( confirmPrompt )
import           XMonad.Prompt.Shell            ( getShellCompl )
import           XMonad.Prompt.Unicode
import           XMonad.Hooks.WorkspaceHistory
import           XMonad.Hooks.ManageDocks ( avoidStruts )

import           XMonad.Util.Font ( Align(..) )
import           XMonad.Util.EZConfig
import           XMonad.Util.SpawnOnce          ( spawnOnOnce )
--import           XMonad.Util.Run hiding (main)--(runProcessWithInput safeSpawn, runInTerm, spawnPipe)
import           XMonad.Operations (refresh, rescreen, windows)

import           XMonad.Actions.CycleWS                       -- Cycle between workspaces and screens
import           XMonad.Actions.DynamicProjects
import           XMonad.Actions.UpdatePointer   ( updatePointer ) -- Keep pointer on active workspace
import           XMonad.Actions.WithAll         ( killAll )
import           XMonad.Actions.FloatKeys ( keysResizeWindow )
import           XMonad.Actions.TreeSelect

import           XMonad.Layout.Named (named)
import           XMonad.Layout.Simplest (Simplest(..))
import           XMonad.Layout.Fullscreen ( fullscreenFloat)
import           XMonad.Layout.BoringWindows ( boringWindows )
import           XMonad.Layout.SubLayouts ( subLayout, subTabbed, pullGroup, GroupMsg(..))
import           XMonad.Layout.Dishes
import           XMonad.Layout.Accordion
import           XMonad.Layout.Drawer

import           XMonad.Layout.Gaps ( gaps, Direction2D(..) )
import           XMonad.Layout.SimpleFloat ( simpleFloat )
import           XMonad.Layout.BinarySpacePartition
import           XMonad.Layout.PerScreen        ( ifWider )
import           XMonad.Layout.PerWorkspace     ( onWorkspace )
import           XMonad.Layout.Spacing                        -- Gap-like spacing
import           XMonad.Layout.Tabbed                            -- Multi-purpose browser tabs
import           XMonad.Layout.SimplestFloat (simplestFloat)
import           XMonad.Layout.Master (mastered)
-- import        Xmonad.Layout.Combo \ ComboP              -- Combine multiple layouts

import           System.Exit
import           Data.Ratio ((%))
import           Data.Tree
import           Data.List ( isInfixOf )
import           Data.Char ( toLower )


--------------------------------------------------------------------------------
-- Layouts
--------------------------------------------------------------------------------

myLayoutHook = fullscreenFloat -- fixes floating windows going full screen, while retaining "bounded" fullscreen
     $ onWorkspace'

  where
    onWorkspace' = onWorkspace wsHome myHomeLayout
       $ onWorkspace wsWeb   (myWebLayout)
       $ onWorkspace wsMedia (gaps myMediaLayout)
       $ gaps defaultLayout

    -- Dishes
    -- drawer = simpleDrawer 0.01 0.3 (ClassName "kitty") `onTop` (Tall 1 0.03 0.5)
    -- defaultLayout = ifWider 1920 (Mirror Accordion ||| Full ||| Tall 1 0.03 0.5 ||| Dishes 2 (1/9)) Full
    defaultLayout = ifWider 1920 (mastered (1/100) (1/2) (responsiveSpacing 8 4 tabs') ||| Full) (Full ||| tabs')
    myHomeLayout  = (responsiveSpacing 8 4 $ tabs' ||| mastered (1/100) (2/3) Simplest) ||| Full
    myWebLayout   = (mastered (1/100) (2/3) (responsiveSpacing 8 4 tabs')) ||| Full
    myMediaLayout = defaultLayout

    tabs' = addTabsBottom shrinkText myTabTheme Simplest
    gaps l = ifWider 1920 (spacing' 8 8 l ||| Full) (spacing' 4 4 l ||| l)
    responsiveSpacing big small l = ifWider 1920 (spacing' big big l) (spacing' small small l)
    spacing' x y = spacingRaw False (Border y (y-2) x x) True (Border y (y-2) x x) True
    border x = Border x x x x
    -- gap' x =  gaps [(U,x), (D,x), (R,x), (L,x)]
    -- spacing'' i o = spacingRaw False (border i) True (border o) True
    -- tabs = named "Tabs"
    --      $ avoidStruts
    --      $ ifWider 1920 (addTabsBottom shrinkText myTabTheme $ Simplest) (Simplest)


--------------------------------------------------------------------------------
-- Workspaces
--------------------------------------------------------------------------------

wsHome = "Home"
wsWeb = "Web"
wsMedia = "Media"
wsDesign = "Design"
wsVirtualbox = "Virtualbox"

myWorkspaces :: Forest String
myWorkspaces =
    [ Node wsHome []
    , Node wsWeb []
    , Node wsMedia []
    , Node wsDesign []
    -- , Node wsVirtualbox []
    ]

-- projects :: [Project]
-- projects =
--     [ Project { projectName      = wsHome
--               , projectDirectory = "~"
--               , projectStartHook = Nothing
--               }
--     , Project { projectName      = wsWeb
--               , projectDirectory = "~"
--               , projectStartHook = Nothing
--               }
--     , Project { projectName      = wsMedia
--               , projectDirectory = "~"
--               , projectStartHook = Nothing
--               }
--     -- , Project { projectName      = wsVirtualbox
--     --           , projectDirectory = "~"
--     --           , projectStartHook = Just $ do
--     --               spawn "virtualbox"
--     --           }
--     ]


--------------------------------------------------------------------------------
-- Hooks
--------------------------------------------------------------------------------

myManageHook :: ManageHook
myManageHook = composeAll
  [ className =? "Inkscape" --> doShift wsDesign
  , className =? "Blender" --> doShift wsDesign
  , className =? "Gimp" --> doShift wsDesign
  , className =? "Zathura" --> doShift wsMedia
  , className =? "qutebrowser" --> doShift wsWeb
  , className =? "Home" --> doShift wsHome
  , className =? "Emacs" --> doShift wsHome
  , className =? "firefoxdeveloperedition" --> doShift wsWeb
  , className =? "firefox" --> doShift wsWeb
  , fmap (isInfixOf "chrome" . (fmap toLower)) className --> doShift wsWeb
  , fmap (isInfixOf "chrome" . (fmap toLower)) appName --> doShift wsWeb
  , className =? "Chrome" --> doShift wsWeb
  , className =? "Cypress" --> doShift wsWeb
  ]


myLogHook :: X ()
myLogHook = do
    updatePointer (0.5, 0.5) (0, 0)  -- Pointer follows focus
    workspaceHistoryHook


--------------------------------------------------------------------------------
-- Themes
--------------------------------------------------------------------------------

purple = "#bd93f9"
cyan = "#8be9fd"
dark = "#21222C"
bg = "#44475A"
fg = "#f8f8f2"
myFont = "xft:Source Code Pro-16"


draculaTheme :: Theme
draculaTheme = def
  { activeColor         = bg
  , inactiveColor       = dark
  , activeTextColor     = fg
  , inactiveTextColor   = fg
  , activeBorderWidth   = 0
  , inactiveBorderWidth = 0
  , fontName            = myFont
  , decoHeight          = 24
  , urgentColor         = bg
  , urgentTextColor     = fg
  }


myTabTheme :: Theme
myTabTheme = draculaTheme
    { fontName = "xft:Source Code Pro-10"
    , decoHeight          = 22
    }


promptTheme :: XPConfig
promptTheme = def
    { font              = myFont
    , bgColor           = bg
    , fgColor           = fg
    , fgHLight          = fg
    , bgHLight          = dark
    , borderColor       = dark
    , promptBorderWidth = 4
    , height            = 100
    , position          = CenteredAt 0.5 0.5
    , autoComplete      = Just 0
    }


myTreeConfig :: TSConfig a
myTreeConfig = TSConfig
    { ts_hidechildren = True
    , ts_background   = 0xc0282a36
    , ts_font         = myFont
    , ts_node         = (0xfff8f8f2, 0xc0282a36)
    , ts_nodealt      = (0xfff8f8f2, 0xc0282a36)
    , ts_highlight    = (0xfff8f8f2, 0xc044475a)
    , ts_extra        = 0xbd93f9
    , ts_node_width   = 300
    , ts_node_height  = 30
    , ts_originX      = 50
    , ts_originY      = 50
    , ts_indent       = 80
    , ts_navigate     = defaultNavigation
    }

--------------------------------------------------------------------------------
-- Prompts
--------------------------------------------------------------------------------

newtype Prompt = Prompt String
instance XPrompt Prompt where
  showXPrompt (Prompt p) = p


mkXPrompt' :: String -> String -> [String] -> XPConfig -> (String -> X ()) -> X ()
mkXPrompt' p t cmds c = mkXPrompt (Prompt p) c' completions
 where
  c'          = c { defaultText = t }
  completions = getShellCompl cmds $ searchPredicate c


quickLaunch :: X ()
quickLaunch = mkXPrompt' "λ " "" cmds promptTheme subLaunch
 where
  cmds = ["volume", "brightness", "screenshot"]


subLaunch :: String -> X ()
subLaunch input =
  let
    t = promptTheme { autoComplete = Nothing }
    newPrompt p d cmd = mkXPrompt' p d [] t $ \x -> spawn $ cmd x
  in

    case input of
      "brightness" ->
        newPrompt (input ++ "(1-10): ") ""
          $ \x -> "xrandr --output eDP-1-1 --brightness "
              ++ show ((read x :: Float) / 10)
      "volume" -> newPrompt (input ++ "(0-150): ") "" $ \x -> "ponymix set-volume " ++ x
      _                  -> pure ()

-- browserProfiles = ["Personal", "InfiniteCloset", "LandDecorInc", "Misc"]
arrow = "\57520"

myTreeselect = treeselectAction myTreeConfig
    [ Node (TSNode "Launcher" "" (spawn "rofi -config /home/trey/.config/rofi/config -show run")) [] -- drun for desktop entries
    -- , Node (TSNode "Browser Profiles" arrow (return ()))
    --     $ browserProfiles <&> (\x -> Node (TSNode x "" (spawn $ "browser-profiles " ++ fmap toLower x)) [])
    , Node (TSNode "XMonad" arrow (return ()))
     [ Node (TSNode "Recompile" "" (spawn "xmonad --recompile && xmonad --restart")) []
     , Node (TSNode "Edit Config" "" (spawn "kitty nvim ~/dev/t-wilkinson/dotfiles/xmonad/xmonad.hs && xmonad --recompile && xmonad --restart")) []
     , Node (TSNode "Logout" "" (io exitSuccess)) []
     ]
    , Node (TSNode "Power" arrow(return ()))
        [ Node (TSNode "Suspend" "" (spawn "systemctl suspend")) []
        , Node (TSNode "Hibernate" "" (spawn "systemctl hibernate")) []
        , Node (TSNode "Shutdown" "" (spawn "shutdown -c now")) []
        ]
    , Node (TSNode "Brightness" arrow (return ()))
        [ Node (TSNode "Screen Off" "" (spawn "sleep 0.5;xset dpms force off")) []
        , Node (TSNode "Bright" ""            (spawn "xrandr --output eDP-1-1 --brightness 1")) []
        , Node (TSNode "Normal" "" (spawn "xbacklight -set 50"))  []
        , Node (TSNode "Dim"    ""              (spawn "xrandr --output eDP-1-1 --brightness 0.2"))  []
        ]
    , Node (TSNode "Reading" "" (spawn "rofi -config /home/trey/.config/rofi/config -show reading -modi reading:~/.config/rofi/reading.sh -matching normal")) [] -- drun for desktop entries
    , Node (TSNode "Scratchpad" "" (spawn "kitty nvim + -c startinsert /home/trey/dev/t-wilkinson/projects/notes/2021245091035.md")) []
    , Node (TSNode "Screenshot" "" (spawn "gnome-screenshot -a -f /home/trey/media/screenshots/\"$(date)\"")) []
    -- , Node (TSNode "Sound" arrow (return ()))
    --     [ Node (TSNode "Raise Volume" "" (spawn "ponymix increase 3")) []
    --     , Node (TSNode "Lower Volume" "" (spawn "ponymix decrease 3")) []
    --     , Node (TSNode "Mute"      ""  (spawn "ponymix toggle")) []
    --     ]
    ]

--------------------------------------------------------------------------------
-- Key Bindings
--------------------------------------------------------------------------------

myKeyBindings :: XConfig l -> XConfig l
myKeyBindings conf = additionalKeysP
  conf
    -- Launching programs
  [ ("M-<Return>", spawn myTerm)
  , ("M-n", spawn "neovide")
  , ("M-m", spawn $ myTerm ++ " glances")
    -- , Node (TSNode "Glances" "" (spawn "rofi -config /home/trey/.config/rofi/config -show reading -modi reading:~/.config/rofi/reading.sh -matching normal")) [] -- drun for desktop entries
  , ("M-e", myTreeselect)
  , ("M-u", typeUnicodePrompt "/home/trey/.xmonad/UnicodeData.txt" promptTheme) -- requires `xdotool`
  , ("M-U", unicodePrompt "/home/trey/.xmonad/UnicodeData.txt" promptTheme) -- requires `xsel`
  , ("M-r", spawn "xmonad --restart")

    -- Workspaces
  -- , ("M-w"  , switchProjectPrompt promptTheme)
  -- , ("M-S-w", shiftToProjectPrompt promptTheme)
  , ("M-w"  , treeselectWorkspace myTreeConfig myWorkspaces W.greedyView)
  , ("M-S-w", treeselectWorkspace myTreeConfig myWorkspaces W.shift)
  , ( "M1-<Tab>" , toggleWS)

    -- Windows
  , ("M-j"          , windows W.focusDown)
  , ("M-k"          , windows W.focusUp)
  , ("M-S-j"        , windows W.swapDown)
  , ("M-S-k"        , windows W.swapUp)

  -- , ("M-m"          , windows W.focusMaster)
  -- , ("M-S-m"        , windows W.swapMaster)
  , ("M-,"          , sendMessage (IncMasterN 1))
  , ("M-."          , sendMessage (IncMasterN (-1)))
  , ("M-h"          , sendMessage (ExpandTowards L))
  , ("M-l"          , sendMessage (ExpandTowards R))
  , ("M-<Backspace>", kill)
  , ("M-S-<Backspace>" , confirmPrompt promptTheme "Kill All" killAll)
  , ("M-s" , withFocused $ windows . W.sink)

--   , ("M1-d", withFocused (keysResizeWindow (-10,-10) (1%2,1%2)))
--   , ("M1-s", withFocused (keysResizeWindow (10,10) (1%2,1%2)))

    -- emptyBSP
  , ("M1-<Left>"   , sendMessage $ ExpandTowards L)
  , ("M1-<Right>"  , sendMessage $ ShrinkFrom L)
  , ("M1-<Up>"     , sendMessage $ ExpandTowards U)
  , ("M1-<Down>"   , sendMessage $ ShrinkFrom U)
  , ("M1-C-<Left>" , sendMessage $ ShrinkFrom R)
  , ("M1-C-<Right>", sendMessage $ ExpandTowards R)
  , ("M1-C-<Up>"   , sendMessage $ ShrinkFrom D)
  , ("M1-C-<Down>" , sendMessage $ ExpandTowards D)
  -- , ("M1-s"        , sendMessage $ Swap)
  , ( "M1-r" , sendMessage $ Rotate)

    -- Screens
  , ( "M-<Tab>" , nextScreen)

    -- Layouts
  , ("M-<Space>", sendMessage NextLayout)
  , ( "M-S-<Space>" , sendMessage FirstLayout)

    -- FN keys
  , ("<XF86AudioRaiseVolume>", spawn "amixer set Master 5%+")
  , ("<XF86AudioLowerVolume>", spawn "amixer set Master 5%-")
  , ("<XF86AudioMute>"       , spawn "ponymix toggle")
  , ("<XF86MonBrightnessUp>", spawn "xbacklight -inc 20")
  , ("<XF86MonBrightnessDown>", spawn "xbacklight -dec 20")
  , ("M1-<F1>"       , spawn "amixer set Master toggle")
  , ("M1-<F2>", spawn "amixer set Master 5%-")
  , ("M1-<F3>", spawn "amixer set Master 5%+")
  , ("M1-<F4>", return ())
  , ("M1-<F11>", spawn "xbacklight -dec 20")
  , ("M1-<F12>", spawn "xbacklight -inc 20")
  ]


--------------------------------------------------------------------------------
-- Config
--------------------------------------------------------------------------------

myTerm = "/home/trey/.local/kitty.app/bin/kitty"
myConf = def { normalBorderColor  = dark
             , focusedBorderColor = bg
             , terminal           = myTerm
             , layoutHook         = myLayoutHook
             , manageHook         = myManageHook
             -- , workspaces         = myWorkspaces
             , workspaces         = toWorkspaces myWorkspaces
             , modMask            = mod4Mask
             , borderWidth        = 2
             , logHook            = myLogHook
             }


--------------------------------------------------------------------------------
-- MAIN
--------------------------------------------------------------------------------

main :: IO ()
main = do
  xmonad
      -- $ dynamicProjects projects
      $ myKeyBindings myConf

