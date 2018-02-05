-- Artista: Calcagno, Misael Dominique. Legajo: CyT-6322 					--


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity vga_ctrl is
	port (
	    clk: in std_logic;		-- Reloj del sistema
        red_i: in std_logic;	 
        grn_i: in std_logic;	
        blu_i: in std_logic;	
        hs: out std_logic;		-- Sincronismo horizontal
        vs: out std_logic;		-- Sincronismo vertical
        red_o: out std_logic;	-- Salida de color rojo	
        grn_o: out std_logic;	-- Salida de color verde
        blu_o: out std_logic;	-- Salida de color azul
		pixel_x: out std_logic_vector(9 downto 0);	-- Posición horizontal del pixel en la pantalla
		pixel_y: out std_logic_vector(9 downto 0)	-- Posición vertical del pixel en la pantalla
	);
end vga_ctrl;

architecture vga_ctrl_arq of vga_ctrl is

component ffd
	port(
		clk: in std_logic;
		rst: in std_logic;
		ena: in std_logic;
		D: in std_logic;
		Q: out std_logic
	);	
end component;

component c_bu
	port(
		clk: in std_logic;
		rst: in std_logic;
		ena: in std_logic;
		D: in std_logic;
		Q: out std_logic;
		C: out std_logic
	);	
end component;

--	constant hpixels: unsigned(9 downto 0) := to_unsigned(800, 10);	-- Número de pixeles en una linea horizontal (800, "1100100000")
--	constant vlines: unsigned(9 downto 0) := to_unsigned(521, 10);	-- Número de lineas horizontales en el display (521, "1000001001")
	
--	constant hpw: natural := 96; 									-- Ancho del pulso de sincronismo horizontal [pixeles]
--	constant hbp: unsigned(7 downto 0) := to_unsigned(144, 8);		-- Back porch horizontal (144, "0010010000")
--	constant hfp: unsigned(9 downto 0) := to_unsigned(784, 10);	 	-- Front porch horizontal (784, "1100010000")

--	constant vpw: natural := 2; 									-- Ancho del pulso de sincronismo vertical [líneas]
--	constant vbp: unsigned(9 downto 0) := to_unsigned(31, 10);	 	-- Back porch vertical (31, "0000011111")
--	constant vfp: unsigned(9 downto 0) := to_unsigned(511, 10);		-- Front porch vertical (511, "0111111111")
	
	signal hc, vc: unsigned(9 downto 0);
	signal vidon: std_logic;
	signal rsth, rstv: std_logic;
	
	signal condh: std_logic;
	
	signal D_h, Q_h, C_h: std_logic_vector(10 downto 0);
	signal Qh: std_logic_vector(9 downto 0);
  
	signal screen_h, screen_v: std_logic_vector(9 downto 0); 
   
	signal D_v, Q_v, C_v: std_logic_vector( 9 downto 0);
	signal enah, enav: std_logic;
	signal enahs, Qhs, Dhs: std_logic;
 	signal enavs, Qvs, Dvs: std_logic;
 	signal enahfp, Qhfp, Dhfp, hfp: std_logic;    
 	signal enahbp, Qhbp, Dhbp, hbp: std_logic;   
 	signal enavfp, Qvfp, Dvfp, vfp: std_logic;    
 	signal enavbp, Qvbp, Dvbp, vbp: std_logic; 
 	
begin

--		Contador Horizontal: inicio		--

   enah <= '1';
   
   ffdh: ffd
       port map(
          clk => clk,	     -- Clock del módulo
          rst => rsth,	  	 -- Reset del módulo
          ena => enah,    	 -- Enable del sistema
          D => D_h(0),	  
          Q => Q_h(0)
	  );
   D_h(0) <= not Q_h(0);
   C_h(0) <= Q_h(0);
   
   c_bu_blockh: for i in 1 to 10 generate
	   c_buih: c_bu
	      port map(
	          clk => clk,
	          rst => rsth,
	          ena => enah,
	          D => D_h(i),
	          Q => Q_h(i),
	          C => C_h(i)
	       );
	   D_h(i) <= C_h(i-1);
	 end generate c_bu_blockh;
	 
	-- 801 = 0b 11 0010 0001 X
	-- 800 = 0b 11 0010 0000 X
	
--	1	  =	 1			1				0					0			1				0				0				0		
   condh <= Q_h(10) and Q_h(9) and (not Q_h(8)) and (not Q_h(7)) and Q_h(6) and (not Q_h(5)) and (not Q_h(4)) and (not Q_h(3));   

--  1	=	1				0			1 
   rsth <= condh and (not Q_h(2)) and Q_h(1);

--		Contador Horizontal: fin		--
   
--		Contador Vertical: incio		--
   
--	1	 =	1				0				0			1
   enav <= condh and (not Q_h(2)) and (not Q_h(1)) and Q_h(0);
   
   ffdv: ffd
       port map(
          clk => clk,	     -- Clock del módulo
          rst => rstv,	  	 -- Reset del módulo
          ena => enav,    	 -- Enable del sistema
          D => D_v(0),	  
          Q => Q_v(0)
	  );
   D_v(0) <= not Q_v(0);
   C_v(0) <= Q_v(0);
   
   c_bu_blockv: for i in 1 to 9 generate
	   c_buiv: c_bu
	      port map(
	          clk => clk,
	          rst => rstv,
	          ena => enav,
	          D => D_v(i),
	          Q => Q_v(i),
	          C => C_v(i)
	       );
	   D_v(i) <= C_v(i-1);
	 end generate c_bu_blockv;
	 
   -- 522 = 0b 10 0000 1010

--	1	=	1				0				0				 0					0				0			1				0			1				0				
   rstv <= Q_v(9) and (not Q_v(8)) and (not Q_v(7)) and (not Q_v(6)) and (not Q_v(5)) and (not Q_v(4)) and Q_v(3) and (not Q_v(2)) and Q_v(1) and (not Q_v(0));

--		Contador Vertical: fin		--   

--		Generación del pulso de sicronismo horizontal hs = '1' when (hc <= hpw) else '0'; --
   ffd_hs: ffd
		port map(
          clk => clk,	     -- Clock del módulo
          rst => rsth,	  	 -- Reset del módulo
          ena => enahs,    	 -- Enable del sistema
          D => Dhs,	  
          Q => Qhs
	  );
	Dhs <= not Qhs;
	hs <= Dhs;
	-- 96 = 0b 00 0110 0000 1

--	1	   =		0			0		0			0		0			0		0			0			1			1			1	
	enahs <= (not (Q_h(10) or Q_h(9) or Q_h(8) or Q_h(5) or Q_h(4) or Q_h(3) or Q_h(2) or Q_h(1))) and (Q_h(7) and Q_h(6) and Q_h(0));

--		Generación del pulso de sicronismo vertical vs = '1' when (vc <= vpw) else '0'; --	
	ffd_vs: ffd
		port map(
          clk => clk,	     -- Clock del módulo
          rst => rstv,	  	 -- Reset del módulo
          ena => enavs,    	 -- Enable del sistema
          D => Dvs,	  
          Q => Qvs
	  );
	Dvs <= not Qvs;
	vs <= Dvs;
	-- 2 = 0b 00 0000 0010
	
--	1	   =		0			0		0			0		0			0		0			0		0			1			1
	enavs <= (not (Q_v(9) or Q_v(8) or Q_v(7) or Q_v(6) or Q_v(5) or Q_v(4) or Q_v(3) or Q_v(2) or Q_v(0))) and Q_v(1) and enav;
	
	ffd_hfp: ffd
		port map(
          clk => clk,	     -- Clock del módulo
          rst => rsth,	  	 -- Reset del módulo
          ena => enahfp,    	 -- Enable del sistema
          D => Dhfp,	  
          Q => Qhfp
	  );
	Dhfp <= not Qhfp;
	hfp <= Dhfp;
	-- 784 = 0b 11 0000 1111 1
	enahfp <= (not (Q_h(8) or Q_h(7) or Q_h(6) or Q_h(5))) and Q_h(10) and Q_h(9) and Q_h(4) and Q_h(3) and Q_h(2) and Q_h(1) and Q_h(0);

	ffd_hbp: ffd
		port map(
          clk => clk,	     -- Clock del módulo
          rst => rsth,	  	 -- Reset del módulo
          ena => enahbp,    	 -- Enable del sistema
          D => Dhbp,	  
          Q => Qhbp
	  );
	Dhbp <= not Qhbp;
	hbp <= Qhbp;
	-- 144 = 0b 00 1001 0000 1
	enahbp <= (not (Q_h(10) or Q_h(9) or Q_h(7) or Q_h(6) or Q_h(4) or Q_h(3) or Q_h(2) or Q_h(1))) and Q_h(8) and Q_h(5) and Q_h(0);

	ffd_vfp: ffd
		port map(
          clk => clk,	     -- Clock del módulo
          rst => rstv,	  	 -- Reset del módulo
          ena => enavfp,    	 -- Enable del sistema
          D => Dvfp,	  
          Q => Qvfp
	  );
	Dvfp <= not Qvfp;
	vfp <= Dvfp;
   -- 286 = 0b 01 0001 1110 
	enavfp <= enav and (not (Q_v(9) or Q_v(7) or Q_v(6) or Q_v(5) or Q_v(0))) and Q_v(8) and Q_v(4) and Q_v(3) and Q_v(2) and Q_v(1);
	
	ffd_vbp: ffd
		port map(
          clk => clk,	     -- Clock del módulo
          rst => rstv,	  	 -- Reset del módulo
          ena => enavbp,   	 -- Enable del sistema
          D => Dvbp,	  
          Q => Qvbp
	  );
	Dvbp <= not Qvbp;
	vbp <= Qvbp;
   -- 158 = 0b 00 1001 1110
	enavbp <= enav and (not (Q_v(9) or Q_v(8) or Q_v(6) or Q_v(5) or Q_v(0))) and Q_v(7) and Q_v(4) and Q_v(3) and Q_v(2) and Q_v(1);
	
	vidon <= hfp and hbp and vfp and vbp;
	
    red_o <= vidon and red_i;
    grn_o <= vidon and grn_i;
    blu_o <= vidon and blu_i;
	
	Qh <= (Q_h(10)&Q_h(9)&Q_h(8)&Q_h(7)&Q_h(6)&Q_h(5)&Q_h(4)&Q_h(3)&Q_h(2)&Q_h(1));
	hc <= unsigned (Qh);
	vc <= unsigned (Q_v);
	
	screen_h <= std_logic_vector(hc - 144) ; 
	screen_v <= std_logic_vector(vc -  31) ; 
   
   chufa1: for i in 0 to 9 generate
      
      pixel_x(i) <= screen_h(i) and vidon;
      pixel_y(i) <= screen_v(i) and vidon;
         
   end generate chufa1;
	
		
end vga_ctrl_arq;