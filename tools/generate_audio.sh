#!/usr/bin/env bash
# Procedurally generates lo-fi minimal SFX + ambient BGM loops with ffmpeg.
#
# Design brief: minimal, "文青 puzzle" — short sines / triangles with soft
# envelopes, no percussive sample libraries, no vocals. Output is OGG Vorbis
# for small file size (OGG plays natively on Android via audioplayers).
#
# All sounds are procedurally synthesised; no third-party audio assets are
# bundled. This also means the entire audio pack is permissively CC0.
#
# Re-run this script to regenerate the pack:
#   bash tools/generate_audio.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SFX="$ROOT/assets/audio/sfx"
BGM="$ROOT/assets/audio/bgm"
mkdir -p "$SFX" "$BGM"

OGG_OPTS=(-c:a libvorbis -q:a 4 -ar 44100 -ac 1 -y)

# --- SFX ----------------------------------------------------------------

echo "[sfx] tile_flip"
# Soft wood-tap: 880Hz triangle, 70ms with fast attack + slower decay.
ffmpeg -hide_banner -loglevel error \
  -f lavfi -i "sine=f=880:d=0.07" \
  -af "volume=0.35,afade=t=in:st=0:d=0.002,afade=t=out:st=0.02:d=0.05" \
  "${OGG_OPTS[@]}" "$SFX/tile_flip.ogg"

echo "[sfx] button_tap"
# Slightly brighter + shorter.
ffmpeg -hide_banner -loglevel error \
  -f lavfi -i "sine=f=1320:d=0.05" \
  -af "volume=0.3,afade=t=in:st=0:d=0.002,afade=t=out:st=0.01:d=0.04" \
  "${OGG_OPTS[@]}" "$SFX/button_tap.ogg"

echo "[sfx] coin_earn"
# Two ascending blips C6 → G6.
ffmpeg -hide_banner -loglevel error \
  -f lavfi -i "sine=f=1047:d=0.08" \
  -f lavfi -i "sine=f=1568:d=0.08" \
  -filter_complex "[0:a]volume=0.4,afade=t=out:st=0.05:d=0.03[a];[1:a]volume=0.4,afade=t=in:st=0:d=0.005,afade=t=out:st=0.05:d=0.03,adelay=80|80[b];[a][b]amix=inputs=2:duration=longest:dropout_transition=0" \
  "${OGG_OPTS[@]}" "$SFX/coin_earn.ogg"

echo "[sfx] win"
# Ascending arpeggio C5 E5 G5 C6 with gentle decay.
ffmpeg -hide_banner -loglevel error \
  -f lavfi -i "sine=f=523.25:d=0.18" \
  -f lavfi -i "sine=f=659.25:d=0.18" \
  -f lavfi -i "sine=f=783.99:d=0.25" \
  -f lavfi -i "sine=f=1046.50:d=0.45" \
  -filter_complex "\
    [0:a]volume=0.35,afade=t=out:st=0.12:d=0.06[a0]; \
    [1:a]volume=0.35,afade=t=in:st=0:d=0.005,afade=t=out:st=0.12:d=0.06,adelay=150|150[a1]; \
    [2:a]volume=0.35,afade=t=in:st=0:d=0.005,afade=t=out:st=0.18:d=0.07,adelay=300|300[a2]; \
    [3:a]volume=0.4,afade=t=in:st=0:d=0.005,afade=t=out:st=0.1:d=0.35,adelay=450|450[a3]; \
    [a0][a1][a2][a3]amix=inputs=4:duration=longest:dropout_transition=0" \
  "${OGG_OPTS[@]}" "$SFX/win.ogg"

echo "[sfx] three_star_chime"
# Bell-like stacked harmonics at A6 + E7 with long decay.
ffmpeg -hide_banner -loglevel error \
  -f lavfi -i "sine=f=1760:d=0.9" \
  -f lavfi -i "sine=f=2637:d=0.9" \
  -filter_complex "\
    [0:a]volume=0.3,afade=t=in:st=0:d=0.005,afade=t=out:st=0.1:d=0.8[a]; \
    [1:a]volume=0.18,afade=t=in:st=0:d=0.005,afade=t=out:st=0.05:d=0.85[b]; \
    [a][b]amix=inputs=2:duration=longest:dropout_transition=0" \
  "${OGG_OPTS[@]}" "$SFX/three_star_chime.ogg"

echo "[sfx] streak_break"
# Descending glide from 440 → 165 Hz, muted.
ffmpeg -hide_banner -loglevel error \
  -f lavfi -i "aevalsrc=0.4*sin(2*PI*(440-275*t/0.5)*t):duration=0.5" \
  -af "afade=t=in:st=0:d=0.01,afade=t=out:st=0.2:d=0.3" \
  "${OGG_OPTS[@]}" "$SFX/streak_break.ogg"

# --- BGM ----------------------------------------------------------------
# Gentle ambient pads built from stacked detuned sines. Loopable because
# the total duration is exactly an integer number of bars at the given
# tempo and every voice fades back to zero at the loop boundary is
# unnecessary (sines are periodic), so a clean cut works.
#
# These are deliberately placeholder-quality — you can drop in real
# lo-fi tracks (CC0 / licensed) into assets/audio/bgm/ at any time and
# they'll be picked up automatically by AudioService.

echo "[bgm] menu_loop"
# Cmaj7 → Am7 → Fmaj7 → G7, 60 BPM, 16s loop (4 bars × 4 beats).
ffmpeg -hide_banner -loglevel error \
  -f lavfi -i "aevalsrc=0.08*sin(2*PI*130.81*t)+0.06*sin(2*PI*196.00*t)+0.05*sin(2*PI*246.94*t)+0.04*sin(2*PI*392.00*t):duration=4" \
  -f lavfi -i "aevalsrc=0.08*sin(2*PI*110.00*t)+0.06*sin(2*PI*164.81*t)+0.05*sin(2*PI*196.00*t)+0.04*sin(2*PI*329.63*t):duration=4" \
  -f lavfi -i "aevalsrc=0.08*sin(2*PI*87.31*t)+0.06*sin(2*PI*130.81*t)+0.05*sin(2*PI*174.61*t)+0.04*sin(2*PI*349.23*t):duration=4" \
  -f lavfi -i "aevalsrc=0.08*sin(2*PI*98.00*t)+0.06*sin(2*PI*146.83*t)+0.05*sin(2*PI*196.00*t)+0.04*sin(2*PI*392.00*t):duration=4" \
  -filter_complex "[0:a][1:a][2:a][3:a]concat=n=4:v=0:a=1,volume=0.7" \
  "${OGG_OPTS[@]}" "$BGM/menu_loop.ogg"

echo "[bgm] gameplay_loop"
# Minor-key variant for gameplay focus: Am7 → Dm7 → Em7 → Am7.
ffmpeg -hide_banner -loglevel error \
  -f lavfi -i "aevalsrc=0.08*sin(2*PI*110.00*t)+0.06*sin(2*PI*164.81*t)+0.05*sin(2*PI*261.63*t)+0.04*sin(2*PI*329.63*t):duration=4" \
  -f lavfi -i "aevalsrc=0.08*sin(2*PI*146.83*t)+0.06*sin(2*PI*220.00*t)+0.05*sin(2*PI*261.63*t)+0.04*sin(2*PI*349.23*t):duration=4" \
  -f lavfi -i "aevalsrc=0.08*sin(2*PI*164.81*t)+0.06*sin(2*PI*246.94*t)+0.05*sin(2*PI*293.66*t)+0.04*sin(2*PI*392.00*t):duration=4" \
  -f lavfi -i "aevalsrc=0.08*sin(2*PI*110.00*t)+0.06*sin(2*PI*164.81*t)+0.05*sin(2*PI*261.63*t)+0.04*sin(2*PI*329.63*t):duration=4" \
  -filter_complex "[0:a][1:a][2:a][3:a]concat=n=4:v=0:a=1,volume=0.65" \
  "${OGG_OPTS[@]}" "$BGM/gameplay_loop.ogg"

echo
echo "Generated:"
ls -lh "$SFX" "$BGM"
