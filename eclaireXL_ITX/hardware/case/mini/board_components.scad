//sio port
module sioport()
{
    sio=[46,22,14];    
    
    color("black")
    union()
    {
        translate([0,sio.y/2-15/2,1.8/2]) cube([sio.x,15,1.8],center=true);
        translate([0,15/2-sio.y/2,14/2]) cube([31,15,14],center=true);
    }
};

//db9
module db9()
{
    db9_screwblock=[30.5,3.5,12];
    db9_portsize=[17,9,6];
    db9_rear=[16,9,11];
    db9_port=[
        [-db9_portsize.x/2,-db9_portsize.y/2],
        [db9_portsize.x/2,-db9_portsize.y/2],
        [(15/17)*db9_portsize.x/2,db9_portsize.y/2],
        [-(15/17)*db9_portsize.x/2,db9_portsize.y/2]
        ];
    translate([0,db9_screwblock.y/2,db9_screwblock.z/2])
    union()
    {
        color("blue")
        cube(db9_screwblock,center=true);
        translate([0,-db9_portsize.z/2-db9_screwblock.y/2,0])
        rotate([-90,0,0])
        linear_extrude(height=db9_portsize.z,center=true)
        polygon(points=db9_port);
        translate([0,db9_rear.y/2+db9_screwblock.y/2,0])
        cube(db9_rear,center=true);
    }
}

module sdcard()
{
    sdcard_dim=[27,28.5,3];
    color("silver")
    translate([0,sdcard_dim.y/2,sdcard_dim.z/2])
    cube(sdcard_dim,center=true);
}

module vertusb()
{
    vertusb_dim=[6,19,15];
    color("grey")
    translate([0,vertusb_dim.y/2,vertusb_dim.z/2])
    cube(vertusb_dim,center=true);
}

module jack()
{
    jack_box=[8,14,13];
    jack_cyl_rad=3;
    jack_cyl_len=4;
    union()
    {
        color("lime")
        translate([0,jack_box.y/2+jack_cyl_len,jack_box.z/2])
        cube(jack_box,center=true);
        color("red")
        translate([-1.2,0,7.2])
        rotate([-90,0,0])
        cylinder(h=4,r=3,center=false);
    }
}

module hdmi()
{
   hdmi_portsize=[14,9.5,5.5];
   hdmi_port=[
    [-hdmi_portsize.x/2,-hdmi_portsize.z/2],
    [hdmi_portsize.x/2,-hdmi_portsize.z/2],
    [hdmi_portsize.x/2,hdmi_portsize.z/8],   
    [(10/14)*hdmi_portsize.x/2,hdmi_portsize.z/2],
    [-(10/14)*hdmi_portsize.x/2,hdmi_portsize.z/2],
    [-hdmi_portsize.x/2,hdmi_portsize.z/8]
    ]; 
    
    color("silver")
    translate([0,hdmi_portsize.y/2,hdmi_portsize.z/2])
    rotate([-90,0,0])
    linear_extrude(height=hdmi_portsize.y,center=true)
    polygon(points=hdmi_port);
}

module switch()
{
    back_size=[6,10,15];
    rocker_block=[9,8,8]; 
    tri_size=[0.2,back_size.y-3,7];
    
    union()
    {
        color("red")
        translate([0,back_size.y/2,back_size.z/2])
        cube(back_size,center=true);
        color("black") 
        translate([0,-tri_size.y+4,back_size.z/2])
        rotate([-5,0,180])
        translate([-rocker_block.x/2,0,0])
        union()
        {
            translate([0,0,-rocker_block.z])              
            cube(rocker_block,center=false);     
            rotate([-25,0,0])
            cube(rocker_block,center=false);
        }
        color("grey")
        translate([back_size.x/2,0,back_size.z/2])
        rotate([0,90,180])
        linear_extrude(height=tri_size.x,center=true)
        polygon([[-tri_size.y/2,0],[0,tri_size.z],[tri_size.y/2,0]]);        
        color("grey")
        translate([-back_size.x/2,0,back_size.z/2])        
        rotate([0,90,180])
        linear_extrude(height=tri_size.x,center=true)
        polygon([[-tri_size.y/2,0],[0,tri_size.z],[tri_size.y/2,0]]);
    }
}

module power_in()
{
    difference()
    {
    union()
    {        
    color("grey") 
    translate([0,1.5,10.5/2])
    cube([9,3,10.5],center=true);        
    color("grey")        
    translate([0,0,6])
    rotate([-90,0,0])        
    cylinder(h=13,r=4,center=false);  
    color("grey")        
    translate([0,13/2,8/2])
    cube([8,13,6],center=true);         
    }
    translate([0,-0.01,6])
    rotate([-90,0,0])
    cylinder(h=12,r=3,center=false);
    }
}

module cart()
{
    cartslot_size=[41.5,2,16];
    cartblock_size=[54,13,16];
    cartwing_size=[52,2,16];
    carttip_size=[5,1.8,6];
    color("white")
    translate([0,0,cartblock_size.z/2])
    difference()
    {
        union()
        {
        cube(cartblock_size,center=true);
        translate([0,cartblock_size.y/2+3,0])
        cube(cartwing_size,center=true);
        translate([cartslot_size.x/2,0,cartslot_size.z/2+carttip_size.z/2])
        cube(carttip_size,center=true);
        translate([-cartslot_size.x/2,0,cartslot_size.z/2+carttip_size.z/2])
        cube(carttip_size,center=true);
        }
        cube(cartslot_size,center=true);
    }    
}
