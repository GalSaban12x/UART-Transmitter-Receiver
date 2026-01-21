package uart_constants is

   constant clockfreq  : integer := 25000000 ;
   constant baud       : integer := 115200   ;
   constant t1_count   : integer := clockfreq / baud ; -- 217
   constant t2_count   : integer := t1_count / 2     ; -- 108

end uart_constants ;

-------------------------------------------------------------------------------------

-------------------------------------------------------
-- UART transmitter (C) VHDL workshop Amos Zaslavsky --
-------------------------------------------------------
use work.uart_constants.all ;
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;
entity transmitter is
   port ( resetN    : in     std_logic                    ;
          clk       : in     std_logic                    ;
          write_din : in     std_logic                    ;
          din       : in     std_logic_vector(7 downto 0) ;
          tx        : out std_logic                       ;
          tx_ready  : out std_logic                       ) ;
end transmitter ;

architecture arc_transmitter of transmitter is
   -- timer            floor(log2(t1_count)) downto 0
   signal tcount : std_logic_vector(8 downto 0) ;
   signal te     : std_logic ; -- Timer_Enable/!reset
   signal t1     : std_logic ; -- end of one time slot
   
   -- data counter
   signal dcount     : std_logic_vector(2 downto 0) ; -- data counter
   signal ena_dcount : std_logic                    ; -- enable this counter
   signal clr_dcount : std_logic                    ; -- clear this counter
   signal eoc        : std_logic                    ; -- end of count (7)

   -- shift register
   signal dint      : std_logic_vector(7 downto 0) ;
   signal ena_shift : std_logic                    ; -- enable shift register
   signal ena_load  : std_logic                    ; -- enable parallel load

   -- output flip-flop --
   signal clr_tx : std_logic ; -- clear  tx during start bit
   signal set_tx : std_logic ; -- set    tx during stop  bit
   signal ena_tx : std_logic ; -- enable tx from shift register during data transfer

  -- state machine
   type state is
   ( idle        ,
     send_start  ,
     clear_timer ,
     send_data   ,
     test_eoc    ,
     shift_count ,
     send_stop   ) ;

    signal present_state , next_state : state ;

begin

   -------------------
   -- state machine --
   -------------------
    process ( resetN , clk )   
   begin
      if resetN = '0' then
         present_state <= idle ;
      elsif rising_edge(clk) then
         present_state <= next_state ;
      end if ;
   end process ;
   
   
   process ( present_state , write_din , t1 , eoc )
   begin
   tx_ready<='0'; clr_dcount<='0'; 
   te<='0';  clr_tx<='0';    ena_tx<='0'; ena_shift<='0';  ena_dcount<='0';
   set_tx<='0'; ena_load <='0';
      next_state <= idle;
      case present_state is
         when idle   =>
             tx_ready<='1';
             ena_load<='1';
             clr_dcount<='1';
             if write_din='0' then
                 next_state <= idle ;
             elsif write_din='1' then
                  next_state <= send_start;
             end if ;
         when send_start=>
             te<='1';
             clr_tx<='1';
            if t1='0' then
                 next_state <= send_start ;
            elsif t1='1' then
                  next_state <= clear_timer;
            end if ;
            
         when clear_timer=>
            next_state <= send_data;
            
           
         when send_data=>
              te <='1';
              ena_tx<='1';
            if t1='0' then
                 next_state <= send_data ;
            elsif t1='1' then
                  next_state <= test_eoc;
            end if ;
            
         when test_eoc=>  
            if eoc='0' then
                 next_state <= shift_count ;
            elsif eoc='1' then
                  next_state <= send_stop;
            end if ;
            
            
            
         when shift_count=>
            ena_shift <='1';
            ena_dcount <='1';
         next_state <=send_data;
         
         when send_stop=>
             te <='1';
             set_tx<='1';             
            if t1='1' then
                 next_state <= idle ;
            elsif t1='0' then
                  next_state <= send_stop;
            end if ;
      end case ;
   end process;
   -----------
   -- timer --
   -----------
   
    process(clk,resetN)
  begin
      if resetN='0' then
        tcount<=(others =>'0');
      elsif rising_edge(clk) then
         if te='1' then
            if tcount/= t1_count then
               tcount <=tcount+1;
            end if;
         else 
         tcount<=(others =>'0');
         end if; 
      end if;        
  end process; 
    
  t1<= '1' when (t1_count <= tcount)  else '0';  

   ------------------
   -- data counter --
   ------------------
   
    process(clk,resetN)
  begin
      if resetN='0' then
        dcount<=(others =>'0');
      elsif rising_edge(clk) then
        if clr_dcount='1' then 
           dcount<=(others =>'0');
        elsif ena_dcount='1' then 
          dcount <= dcount + 1;
        end if;     
      end if;        
  end process; 
    
  eoc<= '1' when (dcount="111" )  else '0';  

   --------------------
   -- shift register --
   --------------------
    process(clk,resetN)
    begin
      if resetN='0' then
        dint<=(others =>'0');
      elsif rising_edge(clk) then
        if write_din='1' and ena_load='1' then
           dint <= din; 
        elsif ena_shift='1' then 
          dint<= '0' & dint(7 downto 1);  
        end if;          
      end if;        
   end process; 
    
    

   ----------------------
   -- output flip-flop --
   ----------------------
   process(clk,resetN)
    begin
      if resetN='0' then
         tx<='1';
      elsif rising_edge(clk) then
        if clr_tx='1' then
           tx<='0'; 
        elsif set_tx='1' then 
              tx<='1';
        elsif ena_tx='1' then 
              tx<= dint(0);        
        end if;          
      end if;        
   end process; 
   
   

end arc_transmitter ;

-------------------------------------------------------------------------------------
