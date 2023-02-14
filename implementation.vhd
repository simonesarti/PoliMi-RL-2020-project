library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

--ENTITY
entity project_reti_logiche is
	port (
		i_clk : in std_logic;									--segnale di CLOCK in ingresso generato dal TestBench
		i_start : in std_logic;									--segnale di START generato dal TestBench;
		i_rst : in std_logic;									--segnale di RESET che inizializza la macchina pronta per ricevere il primo segnale di START
		i_data : in std_logic_vector(7 downto 0);				--segnale (vettore) che arriva dalla memoria in seguito ad una richiesta di lettura
		o_address : out std_logic_vector(15 downto 0);			--segnale (vettore) di uscita che manda l’indirizzo richiesto/da scrivere alla memoria
		o_done : out std_logic;									--s di uscita, comunica la fine dell’elaborazione e il dato di uscita scritto in memoria
		o_en : out std_logic;									--s di ENABLE da dover mandare alla memoria per poter comunicare (sia lettura che scrittura)
		o_we : out std_logic;									--s di WRITE ENABLE da mandare alla memoria per poter scriverci (=1) e leggere (=0)
		o_data : out std_logic_vector (7 downto 0)				--segnale (vettore) di uscita dal componente verso la memoria, contiene il risultato
	);
end project_reti_logiche;

--ARCHITECTURE
architecture behavioral of project_reti_logiche is

	signal ciclo_completo : std_logic :='0';
	signal fine : std_logic :='0';		--serve perchè non posso leggere o_done per vedere se è 1 visto che è di tipo out	

	signal WZ_bit : std_logic :='0';
	signal valore_convertito : std_logic_vector(7 downto 0) :="00000000";

	signal indirizzo_convertire_in : std_logic_vector(7 downto 0);
	signal indirizzo_convertire_out : std_logic_vector(7 downto 0);
	signal base_WZ_in : std_logic_vector(7 downto 0);
	signal base_WZ_out : std_logic_vector(7 downto 0);

	signal counter : integer range 11 downto 0:=11;

	--componenti

	component address_register is		
		port(
			reg_rst : in std_logic;
			reg_clk : in std_logic;
			reg_in : in std_logic_vector(7 downto 0);
			reg_out : out std_logic_vector(7 downto 0)
		);
	end component;

begin
				
				indirizzo_convertire : address_register
				port map(reg_rst=>i_rst, reg_clk=>i_clk, reg_in=>indirizzo_convertire_in, reg_out=>indirizzo_convertire_out);
				
				base_WZ : address_register
				port map(reg_rst=>i_rst, reg_clk=>i_clk, reg_in=>base_WZ_in, reg_out=>base_WZ_out);

				 
				process(i_clk,i_rst)
				begin
				
					--se reset alzato reinizializzo tutti i segnali al loro valore di defaut
					if (i_rst='1') then
						
						--registri e contatore vengono azzerati in automatico

						--segnali di output
						o_en <= '0';
						o_we <= '0';
						o_address <= "0000000000001111"; --indirizzo 15 per evitare problemi
						o_data <= "00000000";

						--segnali interni al componente
						ciclo_completo <= '0';												
						fine<='0';		--darà il valore a o_done	

						counter<=11;				

					--se reset basso e start altro inizio la conversione	
					elsif (rising_edge(i_clk)) then

						if (i_start ='1') then

							--se avessi già fine un ciclo completo o avessi già trovato il risulato, esso è già in memoria, non ha senso ricalcolare tutto
							if(ciclo_completo='1') then
								fine <='1';
								o_address <= "0000000000001111";		--inidirizzo 15 per evitare problemi
								o_we <= '0';
								o_data <= "00000000";
								counter<=11;

							else
								--se ho trovato che sono in una WZ scrivo il risultato in memoria e termino
								if(WZ_bit='1') then
									o_we <= '1';
									o_address <= "0000000000001001";		--inidirizzo 9
									o_data <= valore_convertito;
									ciclo_completo <='1';

								--altrimenti vado avanti con la lettura dei valori dalla ram, alzando il segnale di enable						
								else
									
									if(counter>=3) then
										o_address <= "00000000" & std_logic_vector(to_unsigned(counter-3,8));
										o_en <= '1';
										counter<=counter-1;		

									--mi servono due ciclo di clock bonus per verificare tutti gli indirizzi
									elsif(counter=2 or counter=1) then
										counter<=counter-1;

									--se ho letto E salvato tutti gli indirizzi e non sono in nessuna WZ termino scrivendo il valore originale
									else
										o_we <= '1';
										o_address <= "0000000000001001";		--inidirizzo 9
										o_data <= indirizzo_convertire_out;
										ciclo_completo <= '1';

									end if;
								end if;
							end if;
						
						else
							--se bassi sia reset che start, se done è alto lo abbasso
							if(fine='1') then
								fine<='0';
								o_en<='0';
								ciclo_completo<='0';
								
							end if;

						end if;


					end if;

				end process;

				o_done<=fine;


				--DIREZIONAMENTO DEGLI INGRESSI
				process(i_rst,i_clk)			

				begin

					if(i_rst='1') then
						indirizzo_convertire_in<="00000000";
						base_WZ_in<="00000000";					
					else
						if(falling_edge(i_clk))	then
						
							if(counter=9) then
								indirizzo_convertire_in<=i_data;
							elsif(counter<9) then								
								base_WZ_in<=i_data;
							
							end if;
						end if;					
					end if;

				end process;

				--CONVERSIONE
				process(i_rst,i_clk) 					
				
				variable diff : signed(7 downto 0);
				variable to_shift :unsigned(3 downto 0) := "0001";
					
				begin

					if(i_rst='1') then
						WZ_bit<='0';
						valore_convertito<="00000000";
					
					else
						if(falling_edge(i_clk)) then
							
							if(fine='1') then
								WZ_bit<='0';
								valore_convertito<="00000000";
							else
								if(counter<8) then					
									diff:=(signed(indirizzo_convertire_out))-(signed(base_WZ_out));
									
									if(diff>="00000000" and diff<="00000011") then
										WZ_bit<='1';						
										valore_convertito <= '1' & std_logic_vector(to_unsigned(counter,3)) & std_logic_vector(shift_left(to_shift,to_integer(diff)));
										--valore_convertito<= 1 & WZ_num & WZ_offset
									end if;
								end if;
							end if;
						end if;
					end if;

				end process;




end behavioral;

--
library ieee;
use ieee.std_logic_1164.all;

entity address_register is

	port(
		reg_rst : in std_logic;
		reg_clk : in std_logic;
		reg_in : in std_logic_vector(7 downto 0);
		reg_out : out std_logic_vector(7 downto 0)
	);
end address_register;

architecture behavioral of address_register is
begin
	
	process(reg_clk, reg_rst)
	begin
		
		if (reg_rst = '1') then
			reg_out <= (others => '0');
		elsif (rising_edge(reg_clk)) then
			reg_out <= reg_in;
		end if;
	
	end process;
end behavioral;