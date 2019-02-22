include <board_components.scad>;

board=[170,130,1.2];
cart_loc=[136.83,95.453-40];
power_loc=[21.463,board.y,0];
switch_loc=[34.51,board.y,0];
hdmi_loc=[51,board.y+2+1,0];
db15_loc=[81,board.y+2,0];
jack_loc = [(102.1+110)/2,board.y,0];
vertusb2_loc = [126.428,board.y,0];
vertusb1_loc = [116.538,board.y,0];
sdcard_loc = [(133.9+162.7)/2,board.y,0];
sio_loc=[21,5,0];
db9_loc1=[60.6,0,0];
db9_loc2=[91.8,0,0];
db9_loc3=[123.1,0,0];
db9_loc4=[154.37,0,0];
holerad=3.6/2;

cutout=[[158.6,168.4],[59-40,64.9-40,66.6-40,128.6-40,130.6-40,136.7-40]];
holes=[[6.937,159.3-40],[6.74,66.17-40],[21.46,89.166-40],[109.252,134.86-40],[117.649,89.166-40],[166.223,159.3-40],[154.179,61.783-40]];

module boardcore()
{
    translate([0,0,-board.z])
    linear_extrude(height=board.z,center=false)
    polygon([
            [0,0],
            [board.x,0],
            
            [board.x,cutout.y[0]],
            [cutout.x[0],cutout.y[0]],
            [cutout.x[0],cutout.y[1]],
            [cutout.x[1],cutout.y[1]],
            [board.x,cutout.y[2]],
            
            [board.x,cutout.y[3]],
            [cutout.x[1],cutout.y[4]],
            [cutout.x[0],cutout.y[4]],
            [cutout.x[0],cutout.y[5]],
            [board.x,cutout.y[5]],
            
            [board.x,board.y],
            [0,board.y]
         ]);     
}

module board()
{
//board
color("teal")
difference()
{
    //translate([0,0,-board.z])
    //cube([board.x,board.y,board.z],center=false);  
        boardcore();
        translate([holes[0].x,holes[0].y,-board.z])    
        cylinder(h=board.z,r=holerad,center=false); 
        translate([holes[1].x,holes[1].y,-board.z])    
        cylinder(h=board.z,r=holerad,center=false);
        translate([holes[2].x,holes[2].y,-board.z])    
        cylinder(h=board.z,r=holerad,center=false); 
        translate([holes[3].x,holes[3].y,-board.z])    
        cylinder(h=board.z,r=holerad,center=false);  
        translate([holes[4].x,holes[4].y,-board.z])
        cylinder(h=board.z,r=holerad,center=false); 
        translate([holes[5].x,holes[5].y,-board.z])    
        cylinder(h=board.z,r=holerad,center=false);        
        translate([holes[6].x,holes[6].y,-board.z])    
        cylinder(h=board.z,r=holerad,center=false);       
}

//sio port
translate(sio_loc)
sioport();

//db9
translate(db9_loc1)
db9();

translate(db9_loc2)
db9();

translate(db9_loc3)
db9();

translate(db9_loc4)
db9();

translate(sdcard_loc)
rotate([0,0,180]) sdcard();

translate(vertusb1_loc)
rotate([0,0,180]) vertusb();

translate(vertusb2_loc)
rotate([0,0,180]) vertusb();

translate(jack_loc)
rotate([0,0,180]) jack();

translate(db15_loc)
rotate([0,0,180]) db9();

translate(hdmi_loc)
rotate([0,0,180]) hdmi();

translate(switch_loc)
rotate([0,0,180]) switch();

translate(power_loc)
rotate([0,0,180]) power_in();

translate(cart_loc)
rotate([0,0,270])
cart();
}

//board();