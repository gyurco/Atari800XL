LIBRARY ieee;
USE ieee.std_logic_1164.all;

package Pixels is

type t_Pixel is record
    red   : std_logic_vector(7 downto 0);
    green : std_logic_vector(7 downto 0);
    blue  : std_logic_vector(7 downto 0);
end record t_Pixel;  
  
type t_Pixel2x2 is array (0 to 3) of t_Pixel;
type t_Pixel4x4 is array (0 to (4*4-1)) of t_Pixel;

function pixel_to2x2(v: t_Pixel4x4) return t_Pixel2x2;
function pixel2x2_idx(i,j : integer) return integer;
function pixel4x4_idx(i,j : integer) return integer;

end package Pixels;

package body Pixels is
	function pixel_to2x2(v: t_Pixel4x4) return t_Pixel2x2 is
		variable res : t_Pixel2x2;
	begin
		for i in 0 to 1 loop
			for j in 0 to 1 loop
				res(pixel2x2_idx(i,j)) := v(pixel4x4_idx(i,j));
			end loop;
		end loop;
		return res;
	end pixel_to2x2;
	
	function pixel2x2_idx(i,j : integer) return integer is
		variable res : integer;
	begin
		res := i*2+j;
		return res;
	end pixel2x2_idx;

	function pixel4x4_idx(i,j : integer) return integer is
		variable res : integer;
	begin
		res := i*4+j;
		return res;
	end pixel4x4_idx;	
	
end Pixels;

