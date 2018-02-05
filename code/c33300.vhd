-- Contador con aviso en 33301 y 33300 cuentas (c33300):	--
-- 33301 = 0x8215 = 0b 1000 0010 0001 0101 					--
-- 33300 = 0x8214 = 0b 1000 0010 0001 0100 					--
-- Artista: Calcagno, Misael Dominique. Legajo: CyT-6322	--

library IEEE;
use IEEE.std_logic_1164.all;

entity c33300 is
	port(
		clk: in std_logic;		-- Clock del sistema
		rst: in std_logic;		-- Reset del sistema
		ena: in std_logic;		-- Enable del sistema
		Q_ENA: out std_logic;	-- Aviso a 33300	
 		Q_RST: out std_logic	-- Aviso a 33301
	);
end c33300;

architecture c33300_a of c33300 is
	
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

signal D_i, Q_i, C_i: std_logic_vector(15 downto 0); -- Cables vectoriales para indexación del contador

signal rst_end: std_logic;	-- Cable auxiliar para la lógica del reset de fin de cuenta
signal rst_x: std_logic;	-- Cable auxiliar de reset

signal Q_x: std_logic_vector(3 downto 0);

begin
   
   rst_x <= rst or rst_end; -- Se resetea por fin de cuenta o por sistema
   
   ffd0: ffd
       port map(
          clk => clk,	-- Clock del módulo
          rst => rst_x,	-- Reset del módulo
          ena => ena,  	-- Enable del sistema
          D => D_i(0),	  
          Q => Q_i(0)
	  );
   D_i(0) <= not Q_i(0);
   C_i(0) <= Q_i(0);
   
   c_bu_block: for i in 1 to 15 generate
	   c_bui: c_bu
	      port map(
	          clk => clk,
	          rst => rst_x,
	          ena => ena,
	          D => D_i(i),
	          Q => Q_i(i),
	          C => C_i(i)
	       );
	   D_i(i) <= C_i(i-1);
	 end generate c_bu_block;
--	1		=	1					0					0					0	 
	Q_x(3) <= Q_i(15) and (not (Q_i(14))) and (not (Q_i(13))) and (not (Q_i(12)));

--	1		=		  0					  0				1				  0
	Q_x(2) <= (not (Q_i(11))) and (not (Q_i(10))) and Q_i( 9) and (not (Q_i( 8))); 

--	1		=		  0					  0					  0				1
    Q_x(1) <= (not (Q_i( 7))) and (not (Q_i( 6))) and (not (Q_i( 5))) and Q_i( 4);

--	1		=	1		   1		  1	
    Q_x(0) <= Q_x(3) and Q_x(2) and Q_x(1);

--	1		=	1				0			1				0			  1    
    rst_end <= Q_x(0) and (not Q_i(3)) and Q_i(2) and (not (Q_i(1))) and Q_i(0);

    Q_RST <= rst_end;

--	1		= 1				  0				1				0				0
    Q_ENA <= Q_x(0) and (not Q_i(3)) and Q_i(2) and (not (Q_i(1))) and (not Q_i(0));
    
end;