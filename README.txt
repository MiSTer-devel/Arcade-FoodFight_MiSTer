--------------------------------------------------------------------------------------------------------------
-- 
-- Arcade: Food Fight  for MiSTer by MiSTer-X
-- 26 November 2019
--
-- https://github.com/MrX-8B/MiSTer-Arcade-FoodFight
-- 
--------------------------------------------------------------------------------------------------------------
-- MC68000 compatible softcore
----------------------------------------------------------------------
-- TG68 Revision 1.08
-- Copyright (c) 2007-2010 Tobias Gubener <tobiflex@opencores.org>  
--------------------------------------------------------------------------------------------------------------
-- Pokey
----------------------------------------------------------------------
-- (c) 2013 mark watson
--------------------------------------------------------------------------------------------------------------
-- 
-- 
-- Keyboard inputs :
--
--   F2          : Coin + Start 2 players
--   F1          : Coin + Start 1 player
--   UP,DOWN,LEFT,RIGHT arrows : Movements
--   SPACE,CTRL  : Throw
--
-- MAME/IPAC/JPAC Style Keyboard inputs:
--   5           : Coin 1
--   6           : Coin 2
--   1           : Start 1 Player
--   2           : Start 2 Players
--   R,F,D,G     : Player 2 Movements
--   A,S         : Player 2 Throw
--
--
-- Highly recommend use an analog joystick.
-- For a digital joystick or keyboard, turn on the "Pseudo Analog Stick" in the OSD.
--
-- Immediately after boot, turn the stick several times on the demo screen or in the game for calibration.
--
--------------------------------------------------------------------------------------------------------------

                                *** Attention ***

ROMs are not included. In order to use this arcade, you need to provide the
correct ROMs.

To simplify the process .mra files are provided in the releases folder, that
specifies the required ROMs with checksums. The ROMs .zip filename refers to the
corresponding file of the M.A.M.E. project.

Please refer to https://github.com/MiSTer-devel/Main_MiSTer/wiki/Arcade-Roms for
information on how to setup and use the environment.

Quickreference for folders and file placement:

/_Arcade/<game name>.mra
/_Arcade/cores/<game rbf>.rbf
/_Arcade/mame/<mame rom>.zip
/_Arcade/hbmame/<hbmame rom>.zip
