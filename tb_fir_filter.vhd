--------------------------------------------------------------------------------
-- Biblioteca IEEE
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- Biblioteca para imprimir no console do simulador (opcional, mas bom)
use std.textio.all;
use ieee.std_logic_textio.all;

--------------------------------------------------------------------------------
-- ENTIDADE (O Testbench sempre tem uma entidade vazia)
--------------------------------------------------------------------------------
entity tb_fir_filter is
    -- Vazio
end entity tb_fir_filter;

--------------------------------------------------------------------------------
-- ARQUITETURA (A lógica da simulação)
--------------------------------------------------------------------------------
architecture sim of tb_fir_filter is

    -- 1. Definir os parâmetros GNERICOS do nosso filtro
    -- Eles devem ser IDÊNTICOS aos do 'fir_filter.vhd'
    constant INPUT_WIDTH  : integer := 8;
    constant COEFF_WIDTH  : integer := 8;
    constant OUTPUT_WIDTH : integer := 18;
    
    -- 2. Definir constantes da simulação
    constant CLK_PERIOD : time := 10 ns; -- Período do clock (100 MHz)

    -- 3. Declarar o COMPONENTE que vamos testar
    -- (Isto é basicamente um "copiar e colar" da 'entity' do seu filtro)
    component fir_filter is
        generic (
            INPUT_WIDTH  : integer;
            COEFF_WIDTH  : integer;
            OUTPUT_WIDTH : integer
        );
        port (
            clk     : in  std_logic;
            rst_n   : in  std_logic;
            i_data  : in  std_logic_vector(INPUT_WIDTH - 1 downto 0);
            o_data  : out std_logic_vector(OUTPUT_WIDTH - 1 downto 0)
        );
    end component fir_filter;

    -- 4. Sinais (signals) locais do testbench
    -- (Estes são os "fios" que vão se conectar ao filtro)
    signal s_clk     : std_logic := '0';
    signal s_rst_n   : std_logic := '0';
    signal s_i_data  : std_logic_vector(INPUT_WIDTH - 1 downto 0) := (others => '0');
    signal s_o_data  : std_logic_vector(OUTPUT_WIDTH - 1 downto 0);
    
    -- Sinal para parar o clock (para o simulador)
    signal s_sim_stop : boolean := false;

begin

    -- 5. Instanciar o "Device Under Test" (DUT)
    -- (Aqui nós "criamos" o filtro dentro da simulação)
    UUT : fir_filter
        generic map (
            INPUT_WIDTH  => INPUT_WIDTH,
            COEFF_WIDTH  => COEFF_WIDTH,
            OUTPUT_WIDTH => OUTPUT_WIDTH
        )
        port map (
            clk     => s_clk,
            rst_n   => s_rst_n,
            i_data  => s_i_data,
            o_data  => s_o_data
        );

    -- 6. Gerador de Clock
    -- Este processo roda para sempre, criando o "coração" do sistema
    CLK_GEN_PROCESS : process
    begin
        if not s_sim_stop then
            s_clk <= '0';
            wait for CLK_PERIOD / 2;
            s_clk <= '1';
            wait for CLK_PERIOD / 2;
        else
            wait; -- Para o clock quando a simulação acabar
        end if;
    end process;

    -- 7. Processo de Estímulo (O Teste em si)
    -- Este processo vai enviar os dados para o filtro
    STIMULUS_PROCESS : process
        -- Função para "imprimir" no console (ajuda a depurar)
        procedure print_sim_time is
        begin
            write(output, "INFO: [");
            write(output, now); -- Escreve o tempo atual da simulação
            write(output, "] ");
        end procedure;
    begin
        print_sim_time;
        write(output, "Iniciando Simulação..." & LF);
    
        -- ETAPA 1: Resetar o sistema
        -- (Segura o reset '0' por alguns clocks)
        s_rst_n <= '0';
        s_i_data <= (others => '0');
        wait for CLK_PERIOD * 5; -- Espera 5 ciclos de clock
        
        s_rst_n <= '1'; -- Libera o reset
        print_sim_time;
        write(output, "Sistema fora de reset." & LF);
        wait for rising_edge(s_clk); -- Espera a próxima subida do clock

        -- ETAPA 2: Teste de IMPULSO (O teste mais importante para um filtro!)
        -- Vamos enviar um único '1' e depois '0's.
        -- A saída (o_data) deve "imitar" os coeficientes do filtro: 2, 4, 4, 2
        print_sim_time;
        write(output, "Enviando IMPULSO (valor 1)..." & LF);
        s_i_data <= std_logic_vector(to_signed(1, INPUT_WIDTH));
        wait for rising_edge(s_clk);
        
        -- Agora envia '0's para o resto da simulação do impulso
        s_i_data <= (others => '0');
        
        -- Espera o impulso passar pelo filtro (precisamos de pelo menos 4 clocks)
        wait for rising_edge(s_clk); -- Clock 1 (Saída = 2)
        wait for rising_edge(s_clk); -- Clock 2 (Saída = 4)
        wait for rising_edge(s_clk); -- Clock 3 (Saída = 4)
        wait for rising_edge(s_clk); -- Clock 4 (Saída = 2)
        wait for rising_edge(s_clk); -- Clock 5 (Saída = 0)
        
        print_sim_time;
        write(output, "Impulso concluído." & LF);
        
        -- ETAPA 3: Teste de DEGRAU (Step)
        -- Vamos enviar um valor constante, por exemplo, '5'
        print_sim_time;
        write(output, "Enviando DEGRAU (valor 5)..." & LF);
        s_i_data <= std_logic_vector(to_signed(5, INPUT_WIDTH));
        
        -- Espera alguns clocks para ver a saída estabilizar
        wait for rising_edge(s_clk); -- C1
        wait for rising_edge(s_clk); -- C2
        wait for rising_edge(s_clk); -- C3
        wait for rising_edge(s_clk); -- C4
        wait for rising_edge(s_clk); -- C5
        
        -- O valor final deve ser (2+4+4+2) * 5 = 12 * 5 = 60
        print_sim_time;
        write(output, "Degrau concluído. Saída deve ser 60." & LF);

        -- ETAPA 4: Fim da Simulação
        print_sim_time;
        write(output, "Simulação Concluída." & LF);
        s_sim_stop <= true; -- Para o processo do clock
        wait; -- Para este processo para sempre
        
    end process;

end architecture sim;
