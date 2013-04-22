import XMonad
import XMonad.Actions.Volume
import XMonad.Util.Dzen
import Data.Map (fromList)
import Data.Monoid (mappend)
import Graphics.X11.ExtraTypes.XF86

alert = dzenConfig return . show

main = xmonad defaultConfig {
    borderWidth = 1,
    normalBorderColor = "#000000",
    focusedBorderColor = "#FF0000",
    modMask = mod4Mask,
    terminal = "gnome-terminal --hide-menubar",
    keys = keys defaultConfig `mappend` \c -> fromList [
        ((0, xF86XK_AudioLowerVolume), lowerVolume 4 >>= alert),
        ((0, xF86XK_AudioRaiseVolume), raiseVolume 4 >>= alert)
    ]
}
