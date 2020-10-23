# Copyright (C) 2020 BasedUser
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

# For documentation on this script, please refer to github.com/BasedUser/Denizen-Sheet-Music.


# The following documentation and this line may be safely removed from this file, but the link
# to BasedUser/Denizen-Sheet-Music must remain.

# The Sheet Music System
# A certain person, you perhaps, may want to include this script to make your items participate
# in various songs. For example, making a clock play a harp sound, or some other item playing
# yet another sound.

# This manual won't cover items making sounds on their own when interacted with. This covers the
# book-based MIDI-like structure, how one can make their own music, and what constraints the
# format has.

# 1. THE INSTRUMENTS
# Any item is considered an instrument, so long as it has the NBT tag "sound" with a link to
# that sound, or a Spigot enum. The item itself is just a marker, because the real brains is in
# the NBT tag, or rather, the tags parsing it.

# 2. THE MUSIC
# This script will allow anyone to play music using anything with book data. As such, the book
# should be put into the offhand slot of a player's inventory to be considered a source, and to
# start playback of that book, a stick has to be leftclicked with. Note that you could replace
# the source book with any other book after the playback begins, as there isn't any comparison
# between the two. This is simply a bug in this script. When playing a book, the player may also
# leftclick the stick again to stop playback.

# 3. THE FORMAT
# The playback mechanism doesn't support any old format, it only supports a simple, rudimentary
# format created by myself. Shockingly, it's effective. The format follows like this:
#
#  delay after note plays (ticks), pitch in clicks, slot of instrument, volume;
#             0                  ,       9.5      ,         1         ,   1   ;
#
# Due to the parser's elementary nature, no whitespace is allowed. However, you are allowed to
# cut inbetween a song to the next page, so long as every note is 4 values long and every value
# is defined in their native type. For example, pitch and volume are floating point values,
# whereas delay and slot values are integers. Every note larger or shorter than 4 values long
# will simply be ignored, and skipped. This allows one to create a title page, add a semicolon
# to terminate the note, and start the song on the next page. This hugely improves your song's
# readability by human agents.

# One example of a song is this fragment:
# 6,11,1,1;6,18,1,1;6,23,1,1;6,14,1,1;6,18,1,1;6,23,1,1;6,13,1,1;6,23,1,1;
# This fragment is 8 notes in length, uses the first hotbar slot to play itself at full
# volume, and has 6 ticks of delay after every note. The last note needn't any delay, but is
# preferred to have some to be consistent.
# You can also create chords with notes of delay 0, such as '0,0,1,1;0,3,1,1;0,7,1,1;', which
# is Eb, or E flat, assuming your instrument is tuned to the default Minecraft F# tone.

sheetMusicHandler:
  type: world
  debug: false
  events:
    after player left clicks block with:stick:
    - if !<server.has_flag[instruments_loaded]||true>:
      - stop
    - if !<player.has_flag[playingSheetMusic]> && <player.item_in_offhand.is_book>:
      - flag player playingSheetMusic:<queue>
      - flag player playedSheetMusic:<player.item_in_offhand.book_pages.unseparated.strip_color.split[;]>
      - foreach <player.flag[playedSheetMusic].get[1]> as:note:
        - if <player.item_in_offhand.is_book>:
          - if <[note].split[,].size> == 4:
            - define pause <[note].split[,].get[1]>
            - define pitch <[note].split[,].get[2]>
            - define sound <[note].split[,].get[3]>
            - define volume <[note].split[,].get[4]>
            - inject play_note_task def:<[pitch]>|<[volume]>|<player.inventory.slot[<[sound]>].nbt[sound]>|<player.inventory.slot[<[sound]>].nbt[custom]||false>|<player.location>
            - wait <[pause]>t
        - else:
          - flag player playingSheetMusic:!
          - flag player playedSheetMusic:!
          - determine cancelled
    - else:
      - queue <player.flag[playingSheetMusic]> clear
    - flag player playingSheetMusic:!
    - flag player playedSheetMusic:!

# https://github.com/Soumeh/Denizen_Scripts/blob/master/instruments.dsc

instrument_dependency_loader:
  type: world
  debug: false
  events:
    on script reload:
    - if <server.scripts.parse[name].contains[instrument_handler]>:
      - flag server instruments_loaded:true
    - else:
      - debug log "Dependency missing, make sure that your instruments.dsc file exists and is not corrupted"
      - flag server instruments_loaded:false