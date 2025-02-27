# About the font

## Which font is it

The here used font is [m5x7](https://managore.itch.io/m5x7) by Daniel Linssen in font size 16px.

## How to obtain the font in this format

I used a tool called glyph extractor ([faveris/glyph_extractor](https://github.com/faveris/glyph_extractor)) with some modifications.

```python
import string
letters = string.printable

with TTFont(fontPath, fontNumber=0) as ttfont:
    glyphs = set()
    cmap = ttfont.getBestCmap()
    for key in cmap:
        glyphs.add(key)

    if colored:
        extractSvg(ttfont, glyphs)
    
    readSbix(ttfont, glyphs)

    if len(glyphs) == 0:
        sys.exit(0);

    imagefont = ImageFont.truetype(fontPath, size)
   
    for key in glyphs:
        if whichGlyph and whichGlyph != key:
            continue

        #check if the character is in the list of characters we want to print
        if not chr(key) in letters:
            continue

        text = "" + chr(key)
        filename = f"{hex(key)}.png"

        (left, top, right, bottom) = imagefont.getbbox(text)
        width = right
        height = bottom

        if width <= 0 or height <= 0:
            print(f"{text} -> empty")
            continue
        
        #these values are not applicable to all fonts.
        #rather they have to be obtained by finding the max width and height (individually)
        mywidth = 8
        myheight = 13
        
        try:
            #we only care about yes (pixel) or no (no pixel) so use representation 1 for simplicity
            img = Image.new('1', size=(mywidth, myheight))
            d = ImageDraw.Draw(img)

            d.text((0, 0), text, font=imagefont, fill=1)
            #this seems to smoothen the image, we do not need that here
            #while bleed(img): pass
            #clear(img)
            #d.text((0, 0), text, font=imagefont, embedded_color=colored, fill=fillColor)
            
            #create the two bitmasks
            l_bitmask = 0
            h_bitmask = 0
            for y in range(myheight): # height 
                for x in range(width): # width
                    pixel = img.getpixel((x,y))
                    if pixel == 1:
                        counter = y * width + x
                        if counter >= 64:
                            h_bitmask |= (1 << (counter - 64))
                        else:
                            l_bitmask |= (1 << counter)
            #create the array entry
            print(f"INNER['{text}'] = .{{.size = {width}, .lower = {hex(l_bitmask)}, .higher = {hex(h_bitmask)}}};")
            
            #uncomment this to get an impression how the characters look as going for a too low font size can make them unreadable
            #img.save(os.path.join(outputDir, filename))
            #print(f"{text} -> {filename}")
        except Exception as err:
            print(f"{text} -> {err}", file=sys.stderr)
```

You can simply replace the end of the script with this and should get the same output.

Given here the script was run using the following command:
```sh
python extract_glyphs.py m5x7.ttf --output m5x7 --size 16
```
(the output option is not needed but helpful)

Note: after pasting the result array entries into your code editor you might need to escape certain characters (especially `'` and `\`)