--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- master reset
        btnC    :   in std_logic; -- fsm cycle
        btnL    :   in std_logic; -- clk reset
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
    component sevenseg_decoder is
        port (
            i_hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
  
    component clock_divider is
        generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );
    end component clock_divider;
  
    component TDM4 is
		generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	   );
    end component TDM4;

    component controller_fsm is
        Port ( i_adv : in std_logic;
            i_reset : in std_logic;
            o_cycle : out std_logic_vector(3 downto 0)
       );
    end component controller_fsm;
    
    component twos_comp is
        Port (
        i_bin: in std_logic_vector(7 downto 0);
        o_sign: out std_logic;
        o_hund: out std_logic_vector(3 downto 0);
        o_tens: out std_logic_vector(3 downto 0);
        o_ones: out std_logic_vector(3 downto 0)
       );
    end component twos_comp;
    
    component ALU is
        Port ( 
           i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0)
       );
    end component ALU;
    
    signal w_reset_clk, w_clk, w_sign : std_logic;
    signal w_cycle, w_hund, w_tens, w_ones, w_data, w_sel : std_logic_vector(3 downto 0);
    signal w_alu_result, w_regA, w_regB, w_binVal: std_logic_vector(7 downto 0);
    signal w_seg : std_logic_vector (6 downto 0);
    
begin
	-- PORT MAPS ----------------------------------------
	sevenseg_decoder_inst : sevenseg_decoder
	   port map (
	       i_hex => w_data,
	       o_seg_n => w_seg	   
	 );
	
	clkdiv_inst_tdm : clock_divider 		--instantiation of clock_divider to take 
        generic map ( k_DIV => 50000 ) 
        port map (						  
            i_clk   => clk,
            i_reset => w_reset_clk,
            o_clk   => w_clk
        );
	
	controller_fsm_inst : controller_fsm
	   port map (
	       i_adv   => btnC,
	       i_reset => btnU,
	       o_cycle => w_cycle
	  );
	
	ALU_inst : ALU
	   port map (
	       i_A      => w_regA,
	       i_B      => w_regB,
	       i_op     => sw(2 downto 0),
	       o_result => w_alu_result,
	       o_flags  => led(15 downto 12)
	 );
	
	twos_comp_inst : twos_comp
	   port map (
	       i_bin  => w_binVal,
	       o_sign => w_sign,
	       o_hund => w_hund,
	       o_tens => w_tens,
	       o_ones => w_ones
	  );
	  
	tdm_inst : TDM4
	   port map (
	       i_clk   => w_clk,
	       i_reset => w_reset_clk,
	       i_D2    => w_hund,
	       i_D1    => w_tens,
	       i_D0    => w_ones,
	       o_data  => w_data,
	       o_sel   => w_sel
	 );  
	 
	-- CONCURRENT STATEMENTS ----------------------------
	w_reset_clk <= (btnL or btnU);
	led(3 downto 0) <= w_cycle;
	led(11 downto 4) <= (others => '0');
	
	w_regA <= sw(7 downto 0) when w_cycle = x"2" else
	          "00000000" when w_cycle = x"1";
	w_regB <= sw(7 downto 0) when w_cycle = x"4" else
	          "00000000" when w_cycle = x"1";
	          
	with w_cycle select
	w_binVal <= w_regA when x"2",
	            w_regB when x"4",
	            w_alu_result when x"8",
	            "00000000" when others;
	
	with w_cycle select
	an(3 downto 0) <= "1111" when x"1",
	                   w_sel when others;
	
	with w_seg select
	seg(6 downto 0) <= (not(w_sign) & "111111") when x"7",
	                   w_seg when others;
	                         
end top_basys3_arch;
