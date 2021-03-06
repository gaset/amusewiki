#!/bin/sh

set -e

cd $(dirname $0);
echo "Working in `pwd`";
mkdir -p ../root/static/images/font-preview

for font in 'CMU Serif'            \
            'Linux Libertine O'    \
            'TeX Gyre Termes'      \
            'TeX Gyre Pagella'     \
            'TeX Gyre Schola'      \
            'TeX Gyre Bonum'       \
            'Antykwa Poltawskiego' \
            'Antykwa Torunska'     \
            'Charis SIL'           \
            'PT Serif'             \
            'CMU Sans Serif'       \
            'TeX Gyre Heros'       \
            'TeX Gyre Adventor'    \
            'Iwona'                \
            'Linux Biolinum O'     \
            'DejaVu Sans'          \
            'PT Sans'              \
            'CMU Typewriter Text'  \
            'DejaVu Sans Mono'     \
            'TeX Gyre Cursor'; do
    rm -f font-preview.aux font-preview.tex font-preview.log
    pdf=$(echo $font | sed -e 's/ /-/g').pdf
    if [ ! -f "../root/static/images/font-preview/$pdf" ]; then

    muse-compile.pl --extra papersize=a5 --extra division=15 \
        --extra sitename="$font" \
        --extra nocoverpage=1 \
        --extra fontsize=11 --extra mainfont="$font" \
        --pdf font-preview.muse >/dev/null 2>&1

    mv font-preview.pdf $pdf
    png=$(basename $pdf .pdf).png
    convert -density 150 -trim -quality 100 -sharpen 0x1.0 $pdf[1] $png
    echo "created $pdf and $png"
    mv $pdf $png ../root/static/images/font-preview
    rm -f font-preview.aux font-preview.tex font-preview.log
    fi
done

