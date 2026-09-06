"""Original deterministic pixel sprites and synthesized audio. Run with Python + Pillow + NumPy.
The generated PNG/WAV files are included; Python is NOT needed to play the game.
The forest plate was created with ImageGen. This script never modifies it.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np
import random, math, wave

OUT = Path(__file__).parent / 'assets'
OUT.mkdir(exist_ok=True)
INK='#111f26'; TIMBER='#593f37'; LIGHT='#a07a50'; GOLD='#edbd77'; STONE='#617278'

def save_sprite(im,name): im.save(OUT / (name+'.png'))

def tree(kind):
    r=random.Random(110+kind); im=Image.new('RGBA',(144,184)); d=ImageDraw.Draw(im)
    bark=['#76503d','#695047','#51465f'][kind]
    dark=['#243e32','#2b3c36','#343346'][kind]
    mids=['#375a40','#4a634c','#4f5260'][kind]
    light=['#64815a','#7b8460','#6f7e76'][kind]
    d.ellipse((23,168,127,181),fill='#101f25a0')
    d.polygon([(58,173),(62,144),(66,76),(77,72),(81,139),(87,169),(98,176),(78,175),(70,169),(57,178),(47,176)],fill=INK)
    d.polygon([(63,169),(66,104),(69,64),(76,67),(79,137),(83,172),(72,164)],fill=bark)
    for i in range(18):
        x=r.randrange(67,78); y=r.randrange(90,164);d.line((x,y,x-1,y+r.randrange(4,13)),fill=['#987151','#897060','#80718b'][kind],width=1)
    d.polygon([(70,116),(39,80),(29,77),(47,102),(66,132)],fill=bark)
    d.polygon([(76,94),(100,56),(110,51),(92,91),(79,111)],fill=bark)
    if kind==0:
        for y,w in [(23,15),(45,28),(65,39),(87,49),(108,56),(130,61)]:
            d.polygon([(72,y-21),(72-w,y+13),(77-w,y+13),(71-w,y+20),(96,y+14),(72+w,y+16),(72+w-12,y+5)],fill=dark)
            d.polygon([(71,y-18),(76,y-8),(67+w,y+7),(84,y+7),(85,y+12),(76-w,y+12)],fill=mids)
            d.line((71,y-13,83-w,y+7),fill=light,width=2)
            for j in range(20):
                x=r.randint(75-w,68+w); yy=r.randint(y+5,y+16)
                if im.getpixel((x,yy))[3]:d.rectangle((x,yy,x+r.randrange(2,6),yy+1),fill=r.choice([mids,light,dark]))
    else:
        clusters=[(40,59,29),(71,40,36),(103,60,30),(26,87,22),(62,83,35),(100,94,32),(57,111,27)]
        for x,y,s in clusters:
            if kind==2:y+=r.randrange(-7,8);s-=4
            pts=[(x-s,y-s//3),(x-s+6,y-s+9),(x-9,y-s),(x+10,y-s+3),(x+s-3,y-14),(x+s,y+9),(x+12,y+s-3),(x-11,y+s),(x-s,y+12)]
            d.polygon(pts,fill=dark)
            d.polygon([(px,py-5) for px,py in pts[:-2]],fill=mids)
            for j in range(50):
                xx=r.randrange(max(0,x-s),min(144,x+s)); yy=r.randrange(max(0,y-s),min(160,y+s))
                if im.getpixel((xx,yy))[:3] in [Image.new('RGB',(1,1),v).getpixel((0,0)) for v in [mids,light]]:
                    d.rectangle((xx,yy,xx+r.randrange(1,5),yy+1),fill=r.choice([dark,light,mids]))
        if kind==2:
            d.line((68,144,77,135,76,149,67,139,68,154),fill='#85d6b9',width=2)
            for x,y in [(26,69),(101,94),(68,34),(49,119)]:d.rectangle((x,y,x+2,y+2),fill='#98c9c2')
        else:
            d.rectangle((81,161,86,164),fill='#889460');d.rectangle((83,163,84,170),fill='#b8b98b')
    d.line((66,171,71,177,84,176),fill=LIGHT,width=1)
    save_sprite(im,'tree_'+str(kind))

def building(kind,level):
    r=random.Random(500+kind*7+level); im=Image.new('RGBA',(104,112));d=ImageDraw.Draw(im)
    d.ellipse((4,94,100,108),fill='#1020269b')
    x0=22 if level==1 else 15;y0=60-level*6;x1=83;y1=98
    if kind==5:
        # Each lighthouse level is visibly taller and more elaborate.
        top=38-level*9
        d.polygon([(36,100),(40,top+13),(65,top+13),(71,100)],fill=INK)
        d.polygon([(40,98),(43,top+16),(61,top+16),(66,98)],fill=STONE)
        d.rectangle((44,top+15,50,98),fill='#81908a')
        for y in range(top+20,98,8):
            d.line((42,y,65,y),fill='#455963');d.line((52+(y%3)*3,y,52+(y%3)*3,y+7),fill='#455963')
        d.rectangle((45,85,58,98),fill=INK);d.rectangle((48,87,56,98),fill=TIMBER)
        d.rectangle((33,top+3,73,top+17),fill=INK);d.rectangle((39,top+5,67,top+15),fill=GOLD)
        d.rectangle((44,top+6,62,top+13),fill='#fff0b1')
        d.line((47,top+4,47,top+16),fill=TIMBER,width=2);d.line((59,top+4,59,top+16),fill=TIMBER,width=2)
        d.polygon([(30,top+3),(53,top-10),(76,top+3)],fill='#414856');d.line((33,top+2,53,top-8),fill='#8c8776',width=2)
        if level>1:
            d.rectangle((29,76,37,100),fill=STONE);d.rectangle((70,76,77,100),fill=STONE)
        if level==3:
            d.polygon([(52,top-10),(52,0),(66,3),(52,7)],fill='#b68c60')
            d.rectangle((26,98,80,101),fill='#b6a67b')
        save_sprite(im,f'building_{kind}_{level}');return
    if kind==4:y0-=8
    # Foundation, planks, structural beams.
    d.rectangle((x0-2,y0,x1+2,y1+2),fill=INK)
    d.rectangle((x0,y0,x1,y1),fill=TIMBER)
    d.rectangle((x0+2,y0,x0+10,y1),fill='#856544')
    for y in range(y0+2,y1,5):
        d.line((x0,y,x1,y),fill='#3e3332')
        for j in range(4):
            xx=r.randrange(x0+3,x1-3);d.line((xx,y-2,xx+r.randrange(2,7),y-2),fill='#8c6849')
    d.rectangle((x0+4,y0,x0+7,y1),fill='#ae8b5f');d.rectangle((x1-8,y0,x1-5,y1),fill='#2c3032')
    # Gable roof, hand-placed individual shingles.
    roof=['#3e5e52','#485c61','#534755','#6d4d53','#626155'][kind]
    peak=y0-22-(level-1)*3
    d.polygon([(x0-9,y0+3),((x0+x1)//2,peak-3),(x1+9,y0+3)],fill=INK)
    d.polygon([(x0-7,y0),(52,peak),(x1+6,y0)],fill=roof)
    for y in range(peak+4,y0,4):
        half=int((y-peak)/(y0-peak)*(x1-x0+12)/2)
        d.line((52-half,y,52+half,y),fill='#26353a')
        for x in range(52-half+2,52+half,9): d.line((x,y-2,x+4,y-2),fill='#829083' if kind!=2 else '#8a7780')
    d.line((x0-6,y0-1,52,peak),fill='#899076',width=2)
    # Door, windows, warm pixels.
    doorx=50
    d.rectangle((doorx-8,y1-24,doorx+7,y1),fill=INK);d.rectangle((doorx-5,y1-22,doorx+5,y1),fill='#453734')
    d.line((doorx,y1-20,doorx,y1-2),fill=LIGHT);d.point((doorx+3,y1-12),fill=GOLD)
    for wx in [x0+13,x1-16]:
        d.rectangle((wx-6,y0+9,wx+7,y0+22),fill=INK);d.rectangle((wx-4,y0+11,wx+5,y0+20),fill=GOLD)
        d.line((wx,y0+10,wx,y0+21),fill=TIMBER);d.line((wx-4,y0+15,wx+5,y0+15),fill=TIMBER)
    d.rectangle((x0-3,98,x1+3,101),fill='#65695c')
    # Chimney and level-specific architectural growth.
    if kind!=3:
        d.rectangle((70,peak-3,79,y0-6),fill=INK);d.rectangle((72,peak-4,77,y0-6),fill=STONE)
        for y in range(peak-3,y0-5,4):d.line((72,y,77,y),fill='#3e4b51')
    if level>=2:
        d.rectangle((7,78,24,99),fill=TIMBER);d.polygon([(3,80),(13,68),(29,79)],fill=roof)
        d.rectangle((12,83,19,89),fill=GOLD)
    if level==3:
        d.rectangle((44,peak+8,59,peak+20),fill=INK);d.rectangle((47,peak+10,56,peak+18),fill=GOLD)
        d.line((52,peak+9,52,peak+19),fill=TIMBER)
        d.rectangle((29,96,40,101),fill='#61765b');d.rectangle((32,94,33,98),fill='#c5bb89');d.rectangle((37,93,38,98),fill='#b47b7c')
    if kind==0:
        for yy in [91,96,101]:
            d.rectangle((79,yy-3,98,yy),fill='#704c38');d.ellipse((94,yy-3,99,yy+1),fill='#ba9360')
        d.line((10,92,20,79),fill=LIGHT,width=2);d.polygon([(18,79),(22,76),(26,79),(21,83)],fill='#b8c4bf')
    elif kind==1:
        d.ellipse((71,73,101,103),fill=INK);d.ellipse((74,76,98,100),fill=LIGHT);d.ellipse((78,80,94,96),fill='#343e3c')
        for a in range(0,360,45):
            d.line((86,88,86+int(math.cos(math.radians(a))*11),88+int(math.sin(math.radians(a))*11)),fill='#b69a69',width=2)
        d.ellipse((83,85,89,91),fill=STONE)
        for yy in [95,99,103]:d.rectangle((5,yy,30,yy+1),fill='#b69a69')
    elif kind==2:
        d.rectangle((65,78,89,100),fill=INK);d.rectangle((68,82,85,97),fill='#a75538');d.rectangle((73,86,82,96),fill='#f3c777')
        d.polygon([(2,91),(25,91),(18,96),(8,96)],fill='#9ca5a0');d.rectangle((10,96,16,101),fill=STONE)
    elif kind==3:
        d.rectangle((8,68,99,75),fill=INK)
        for x in range(9,97,11):d.rectangle((x,63,x+10,74),fill='#b09b6b' if x%2 else '#657e72')
        d.line((10,75,10,101),fill=LIGHT,width=2);d.line((96,75,96,101),fill=LIGHT,width=2)
        d.rectangle((15,91,41,100),fill='#876345');d.rectangle((61,91,92,100),fill='#876345')
        for x in [21,27,34,69,76,83]:d.rectangle((x,88,x+3,91),fill='#a1a568')
    elif kind==4:
        d.line((83,55,99,55),fill=TIMBER,width=2);d.rectangle((88,56,99,70),fill=INK);d.rectangle((90,58,97,67),fill='#c3a270');d.rectangle((92,59,95,64),fill=TIMBER)
        d.ellipse((77,91,90,103),fill='#594432');d.line((80,94,88,94),fill=STONE);d.line((80,100,88,100),fill=STONE)
    for i in range(12):
        xx=r.randrange(6,99); yy=r.randrange(100,106);d.line((xx,yy,xx+1,yy-2),fill=r.choice(['#4d6d52','#688259']))
    save_sprite(im,f'building_{kind}_{level}')

def people():
    for frame in range(4):
        im=Image.new('RGBA',(40,48));d=ImageDraw.Draw(im);dy=frame%2
        d.ellipse((6,40,33,46),fill='#102026a0')
        d.rectangle((10,31+dy,17,41),fill=INK);d.rectangle((22,31+dy,28,41),fill=INK)
        d.rectangle((8,39,18,43),fill='#554039');d.rectangle((21,39,31,43),fill='#554039')
        d.polygon([(12,17+dy),(26,17+dy),(31,32+dy),(10,32+dy)],fill='#2e4652')
        d.rectangle((13,21+dy,17,31+dy),fill='#4f6f76');d.rectangle((13,31+dy,27,33+dy),fill='#816447')
        d.rectangle((15,9+dy,27,19+dy),fill='#d0a174');d.rectangle((24,12+dy,29,17+dy),fill='#d0a174')
        d.rectangle((16,16+dy,25,22+dy),fill='#694b3e');d.rectangle((25,12+dy,26,13+dy),fill=INK)
        d.rectangle((12,7+dy,29,11+dy),fill='#ac854e');d.rectangle((15,3+dy,25,7+dy),fill='#977443');d.rectangle((17,3+dy,23,4+dy),fill='#d5ad65')
        d.rectangle((14,20+dy,26,22+dy),fill='#ab6551');d.rectangle((14,22+dy,16,28+dy),fill='#b9715b')
        if frame in [1,2]:
            d.polygon([(25,23),(31,18),(35,19),(31,27),(25,29)],fill='#4f6f76');d.rectangle((31,17,35,21),fill='#d0a174')
        else:
            d.polygon([(25,23+dy),(29,23+dy),(33,29+dy),(29,32+dy),(24,28+dy)],fill='#4f6f76');d.rectangle((29,28+dy,33,31+dy),fill='#d0a174')
        save_sprite(im,'lumberjack_'+str(frame))

def audio():
    sr=22050;rng=np.random.default_rng(251)
    def write(name,x):
        x=np.clip(x,-0.98,0.98)
        with wave.open(str(OUT/(name+'.wav')),'w') as w:
            w.setnchannels(2 if x.ndim==2 else 1);w.setsampwidth(2);w.setframerate(sr);w.writeframes((x*32767).astype('<i2').tobytes())
    for j in range(3):
        t=np.arange(int(sr*0.22))/sr;n=rng.normal(0,1,len(t))
        hit=n*np.exp(-t*48)*0.17+np.sin(2*np.pi*(175+j*19)*t)*np.exp(-t*30)*0.36+np.sin(2*np.pi*690*t)*np.exp(-t*65)*0.14
        write('chop_'+str(j),hit*np.minimum(1,t*2000))
    t=np.arange(sr*1.15)/sr;n=rng.normal(0,1,len(t));fall=n*(0.04+0.06*np.sin(t*17)**2)*np.exp(-t*2)
    for start in [0,.11,.24,.48,.62]:
        tt=np.maximum(t-start,0);fall+=(np.sin(2*np.pi*(80+30*start)*tt)*.26+n*.12)*np.exp(-tt*18)*(t>=start)
    write('fell',fall*np.minimum(1,t*1000))
    def bells(name,notes,length,decay):
        t=np.arange(int(sr*length))/sr;x=np.zeros(len(t))
        for start,f in notes:
            tt=np.maximum(0,t-start); env=(t>=start)*np.minimum(1,tt*300)*np.exp(-tt*decay)
            x+=env*(np.sin(2*np.pi*f*tt)+.25*np.sin(2*np.pi*f*2.01*tt))*.16
        write(name,x)
    bells('coins',[(0,1046),(.07,1397),(.14,1568)],.65,8)
    bells('upgrade',[(0,392),(.1,523),(.2,784)],1.1,5)
    bells('build',[(0,196),(.12,294),(.25,392),(.4,587)],1.3,4)
    bells('whisper',[(0,294),(.28,440),(.65,698),(1.2,587)],3.3,2)
    bells('win',[(0,196),(.25,294),(.5,392),(.8,587),(1.15,784)],4,1.3)
    # Circular envelopes and exact integer periods make the 48-second loop seamless.
    dur=48;t=np.arange(sr*dur)/sr;x=np.zeros(len(t));TAU=2*np.pi
    chords=[(146.83,220,293.66),(130.81,196,261.63),(174.61,220,349.23),(146.83,233.08,293.66)]
    for j,chord in enumerate(chords):
        dist=(t-(j*12+6)+dur/2)%dur-dur/2
        env=np.clip(1-np.abs(dist)/12,0,1)**1.5
        for f in chord:
            f=round(f*dur)/dur
            x+=env*(np.sin(TAU*f*t)+.16*np.sin(TAU*f*2*t))*.025
    x+=np.sin(TAU*73.4166666667*t)*.016
    for start,f in [(2,587.333333),(8,440),(17,523.25),(24,698.458333),(33,587.333333),(41,466.166667)]:
        tt=(t-start)%dur;freq=round(f*dur)/dur
        env=(1-np.exp(-tt*3))*np.exp(-tt*.7)
        x+=np.sin(TAU*freq*tt)*env*.05
    stereo=np.column_stack([x,np.roll(x,int(.023*sr))])
    write('ambient_music',stereo)
    # Soft filtered forest noise and sparse, synthesized bird calls.
    raw=rng.normal(0,1,len(t));spec=np.fft.rfft(raw);freq=np.fft.rfftfreq(len(t),1/sr)
    spec*=np.exp(-freq/1000)*(1-np.exp(-freq/90));wind=np.fft.irfft(spec,n=len(t));wind*=.032/(np.max(np.abs(wind))+1e-9)
    forest=wind*(.7+.25*np.sin(TAU*t/dur))
    for start in [3,11,12,26,39,40]:
        tt=t-start;mask=(tt>0)&(tt<.3);phase=TAU*(1900*tt+600*tt**2);forest+=np.sin(phase)*np.sin(np.clip(tt/.3,0,1)*np.pi)**2*.018*mask
    write('forest_ambience',np.column_stack([forest,np.roll(forest,600)]))

if __name__=='__main__':
    for k in range(3):tree(k)
    for k in range(6):
        for level in range(1,4):building(k,level)
    people();audio();print('Created 25 original pixel sprites and 11 original audio assets.')
