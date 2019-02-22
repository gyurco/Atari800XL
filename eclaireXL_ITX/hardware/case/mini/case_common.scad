include <board.scad>;

thickness=1.2;
casespace=6;
casemain = [board.x+casespace+10+4,board.y+casespace,40];

basex=-db9_loc1.x-18.5; 
basey=-casemain.y/2+4;
spacing=3;

//cartholesize=[86,27,10];
cartholesize=[66,24,21];
cartholesizebig=[66+3,27+3,20];
cartholeloc=[cart_loc.x+basex,basey+cart_loc.y,casemain.z/2-9];

pbiholesize=[85,5,16];
pbiholesizebig=[85+3,4,16+3]; 
pbiholeloc=[171+basex,basey+58,casemain.z/2-25];

sioholesize=[32+spacing,8,14+spacing];
sioholeloc=[basex+sio_loc.x,basey,1];

db9holesize=[18+spacing,8,10+spacing];
db9_first=db9_loc1.x+basex;
db9holelocs=[[db9_first,basey,0],[db9_first+db9_loc2.x-db9_loc1.x,basey,0],[db9_first+db9_loc3.x-db9_loc1.x,basey,0],[db9_first+db9_loc4.x-db9_loc1.x,basey,0]];

basey2=basey+board.y;

sdholeloc=[basex+sdcard_loc.x,basey2,-5];
sdholesize=[27+spacing,14,3+spacing];

usb1loc=[basex+vertusb1_loc.x,basey2,1];
usb1size=[6+spacing,14,15+spacing];

usb2loc=[basex+vertusb2_loc.x,basey2,1];

jackloc=[basex+jack_loc.x+1,basey2,1.5];
jackrad=3+spacing/2;

vgaloc=[basex+db15_loc.x,basey2,0];
vgasize=[30.5+spacing,14,12+spacing];

vidloc=[basex+hdmi_loc.x,basey2,-3];
vidsize=[14+spacing+1,14,5.5+spacing+1];

swloc=[basex+switch_loc.x,basey2,1];
swsize=[10+spacing,14,18+spacing];

powloc=[basex+power_loc.x+1,basey2,0];
powrad=3.5+spacing/2;

module caseremove(casemain)
{
    bottri=8;
    toptri=3;
    corntri=14;
    cornpyr=14;
    topcorn=[-0.01,-0.01];
        
        
        translate([0,-casemain.y/2,casemain.z/2])
        rotate([0,90,0])
        linear_extrude(height=casemain.x,center=true)
        polygon([topcorn,[0,toptri],[toptri,0]]); 
        
        translate([0,casemain.y/2,casemain.z/2])
        rotate([0,90,180])
        linear_extrude(height=casemain.x,center=true)
        polygon([topcorn,[0,toptri],[toptri,0]]);        

        translate([casemain.x/2,0,casemain.z/2])
        rotate([-90,90,0])
        linear_extrude(height=casemain.y,center=true)
        polygon([topcorn,[0,toptri],[toptri,0]]);  
        
        translate([-casemain.x/2,0,casemain.z/2])
        rotate([90,90,0])
        linear_extrude(height=casemain.y,center=true)
        polygon([topcorn,[0,toptri],[toptri,0]]); 
  
        rotate([0,180,0])
        translate([0,-casemain.y/2,casemain.z/2])
        rotate([0,90,0])
        linear_extrude(height=casemain.x,center=true)
        polygon([topcorn,[0,bottri],[bottri,0]]); 
        
        rotate([0,180,0])
        translate([0,casemain.y/2,casemain.z/2])
        rotate([0,90,180])
        linear_extrude(height=casemain.x,center=true)
        polygon([topcorn,[0,bottri],[bottri,0]]);        

        rotate([0,180,0])
        translate([casemain.x/2,0,casemain.z/2])
        rotate([-90,90,0])
        linear_extrude(height=casemain.y,center=true)
        polygon([topcorn,[0,bottri],[bottri,0]]);  
        
        rotate([0,180,0])
        translate([-casemain.x/2,0,casemain.z/2])
        rotate([90,90,0])
        linear_extrude(height=casemain.y,center=true)
        polygon([topcorn,[0,bottri],[bottri,0]]);  
            
        translate([-casemain.x/2,casemain.y/2,0])
        rotate([0,0,-90])
        linear_extrude(height=casemain.z+2,center=true)
        polygon([topcorn,[0,corntri],[corntri,0]]);       

        translate([casemain.x/2+0.001,casemain.y/2+0.001,casemain.z/2+0.001])
        rotate([0,180,90])
            polyhedron(
                   points=[[0,0,0], [cornpyr,0,0], [0,cornpyr,0], [0,0,cornpyr]],
                   faces=[[0,1,2],[1,0,3],[0,2,3],[3,2,1]]
                   );     
}

module case(casemain)
{
    difference()
    {
        cube(casemain,true);
        caseremove(casemain);
    }     
  
}
    
module hollowcase()
{
    // a hollow case!
    translate([10+-casemain.x/2,10+-casemain.y/2,casemain.z/2])
      linear_extrude(height=1.5,center=false)
       text("EclaireXL", font = "Liberation Sans:style=Bold Italic", size=14, spacing=1.05);

    difference()
    {
        case(casemain);
        case([casemain.x-thickness*2,casemain.y-thickness*2,casemain.z-thickness*2]);
    }
}

module portcube(sz,center)
{
    spheresz=2;
    sz2=[sz.x-spheresz*2,sz.y,sz.z-spheresz*2];
    
    minkowski()
    {
    cube(sz2,center=center);
    sphere(r=spheresz);
    }
}

module cartsurround()
{
    //cart guide
    translate(cartholeloc)
    rotate([0,0,90])
    portcube(cartholesizebig,center=true);    
}

module pbisurround()
{         
    // pbi guide
    translate(pbiholeloc)
    rotate([0,00,90])
    portcube(pbiholesizebig,center=true);      
}

module portholes()
{
        //cart hole
        translate(cartholeloc)
        rotate([0,0,90])
        portcube(cartholesize,center=true);
        
        //sio hole
        translate(sioholeloc)
        portcube(sioholesize,center=true); 
 
        //db9 hole
        translate(db9holelocs[0])
        portcube(db9holesize,center=true);         
        translate(db9holelocs[1])
        portcube(db9holesize,center=true); 
        translate(db9holelocs[2])
        portcube(db9holesize,center=true); 
        translate(db9holelocs[3])
        portcube(db9holesize,center=true);  
 
        //sd hole
        translate(sdholeloc)
        rotate([0,0,180])
        portcube(sdholesize,center=true);
        
        //usb hole
        translate(usb1loc)
        rotate([0,0,180])
        portcube(usb1size,center=true);

        translate(usb2loc)
        rotate([0,0,180])
        portcube(usb1size,center=true);
    
        // jack
        color("red")
        translate(jackloc)
        rotate([90,0,180])
        cylinder(r=jackrad,h=20,center=true);      

        // vga
        translate(vgaloc)
        rotate([0,0,180])
        portcube(vgasize,center=true);
    
        // hdmi
        translate(vidloc)
        rotate([0,0,180])
        portcube(vidsize,center=true);
    
        // switch
        translate(swloc)
        rotate([0,0,180])
        portcube(swsize,center=true);
        
        // power
        color("red")
        translate(powloc)
        rotate([90,0,180])
        cylinder(r=powrad,h=20,center=true);      
        
        // pbi hole  
        color("black")
        translate(pbiholeloc)
        rotate([0,00,90])
        portcube(pbiholesize,center=true);    
}

module lowerscrewmain()
{
    screwheight=13;
    screwradout=5.7;
    
    for(hl = [0:6])
    {
    translate([holes[hl].x,holes[hl].y,-board.z-screwheight])    
    cylinder(h=screwheight,r=screwradout,center=false); 
    }  
}

module lowerscrew(hl)
{
    screwheight=12.8;
    screwradout=5.7;
    screwradin=4.5;
    fileth=5;
    filetw=6/2;
  
    translate([holes[hl].x,holes[hl].y,-board.z-screwheight])    
    rotate_extrude()
        difference()
        {
            polygon( 
            points=[
                [screwradout+filetw,0],
                [screwradout+filetw,fileth],
                [screwradout,fileth],
                [screwradout,screwheight],
                [holerad+0.5,screwheight],
                [holerad+0.5,screwheight-1.5],
                [screwradin,screwheight-1.5],
                [screwradin,0]
            ] );
            translate([screwradout+5,5,0])
            circle(r=5,center=true);
        }    
}

module lowerscrews()
{
    for(hl = [0:6])
    {
        lowerscrew(hl);
    } 
}

module upperscrew(hl)
{
    screwheightt=24.5;
    
    filletradout=5/2;
    filleth=4;
    
    headradout=7/2;
    heatrads=3.7/2;
    heatradl=4/2;
    
    heath=5.25;

    translate([holes[hl].x,holes[hl].y,+board.z])    
    rotate_extrude() difference()
        {
            polygon( 
            points=[
                [headradout,0],
                [heatradl,0],
                [heatrads,heath],
                [0,heath],
                [0,screwheightt],
                [headradout+filletradout,screwheightt],
                [headradout+filletradout,screwheightt-filleth],
                [headradout,screwheightt-filleth]
            ] );
            translate([5+headradout,screwheightt-5,0])
            circle(r=5,center=true);
        }
}

module upperscrews()
{
    for(hl = [0,1,5,6])
    {
        upperscrew(hl);
    };                                
}

module wallslice()
{
    hull()
    projection(cut=true)
    translate([0,0,-15])
    intersection()
    {
        hollowcase();
        translate([0,0,65]) cube([200,200,100], center=true);
    }
}

module vent()
{
    rotate([0,-22.5,-45])
    cube([3,40,100],center=true);    
}

module vents()
{
    ventspace=8;
    translate([75,45,0])
    for (i=[1:16])
    {
        translate([-i*ventspace,00])
        vent();
    }
}

///////////////////////////////////////
// Above here are case components

// Full thing with board in
/*union()
{
    board();
    difference()
    {
        translate([casemain.x/2-16,casemain.y/2-4,6])
        difference()
        {   
            union()
            {
                hollowcase();
                pbisurround();
                cartsurround();
            }      
            portholes(); 
        }
        lowerscrewmain();
    }
    lowerscrews();
    upperscrews();  
}*/


// bottom half
module bottomhalf()
{
union()
{
    difference()
    {
        translate([casemain.x/2-16,casemain.y/2-4,6])
        difference()
        {   
            union()
            {
                difference()
                {
                    hollowcase();
                    translate([0,0,65])
                    cube([200,200,100], center=true);
                };
                pbisurround();
                //cartsurround();
            }      
            portholes(); 
        }
        lowerscrewmain();
    }
    difference()
    {
        lowerscrews();
        translate([casemain.x/2-16,casemain.y/2-4,6])
        caseremove(casemain);
    }
}
}

// top half
module tophalf()
{
union()
{
    //board();
    difference()
    {
        translate([casemain.x/2-16,casemain.y/2-4,6])
        difference()
        {   
            union()
            {
                intersection()
                {
                    hollowcase();
                    translate([0,0,65]) cube([200,200,100], center=true);
                }                
                
                difference()
                {
                    translate([0,0,17-2])
                    minkowski()
                    {
                        linear_extrude(height=2,center=true)
                        //offset(r=0.5)
                        wallslice();
                        sphere(r=2);
                    }
                    
                    case(casemain);
                }
                
                cartsurround();
            }      
            portholes(); 
            vents();
        }
    }
    difference()
    {
        upperscrews();
        translate([casemain.x/2-16,casemain.y/2-4,6])
        union()
        {
            caseremove(casemain);
            portholes(); 
        }
    }  
}
}

$fn=40;
//tophalf();
bottomhalf();
//board();

//projection(cut=true)
//translate([0,0,-10])
//surface(file = "atari-symbol-black.png", center = true, convexity = 5,invert=true);
