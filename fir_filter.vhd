--------------------------------------------------------------------------------
-- Biblioteca IEEE (Padrão da indústria)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all; -- Para os tipos básicos (std_logic)
use ieee.numeric_std.all;    -- Para matemática com números (signed, unsigned)

--------------------------------------------------------------------------------
-- ENTIDADE (A "casca" ou "caixa-preta" do seu componente)
-- Define as portas de entrada e saída.
--------------------------------------------------------------------------------
entity fir_filter is
    generic (
        INPUT_WIDTH  : integer := 8;   -- Largura de bits da entrada (ex: 8 bits)
        COEFF_WIDTH  : integer := 8;   -- Largura de bits dos coeficientes
        OUTPUT_WIDTH : integer := 18   -- Largura da saída (precisa ser maior para evitar overflow)
    );
    port (
        -- Sinais de Controle
        clk     : in  std_logic;                     -- Clock (o "coração" do FPGA)
        rst_n   : in  std_logic;                     -- Reset (ativo em '0', "n" de negativo)
        
        -- Sinais de Dados
        i_data  : in  std_logic_vector(INPUT_WIDTH - 1 downto 0);  -- Dado de entrada (x[n])
        o_data  : out std_logic_vector(OUTPUT_WIDTH - 1 downto 0) -- Dado de saída (y[n])
    );
end entity fir_filter;

--------------------------------------------------------------------------------
-- ARQUITETURA (A "lógica interna" do seu componente)
--------------------------------------------------------------------------------
architecture rtl of fir_filter is

    -- 1. Definir os Coeficientes (as constantes "b" do filtro)
    -- Vamos fazer um filtro "passa-baixa" simples
    -- y[n] = 2*x[n] + 4*x[n-1] + 4*x[n-2] + 2*x[n-3]
    constant C0 : signed(COEFF_WIDTH - 1 downto 0) := to_signed(2, COEFF_WIDTH);
    constant C1 : signed(COEFF_WIDTH - 1 downto 0) := to_signed(4, COEFF_WIDTH);
    constant C2 : signed(COEFF_WIDTH - 1 downto 0) := to_signed(4, COEFF_WIDTH);
    constant C3 : signed(COEFF_WIDTH - 1 downto 0) := to_signed(2, COEFF_WIDTH);

    -- 2. Definir os Sinais Internos (os "fios" e "registradores")
    -- Estes são os registradores (Flip-Flops) para guardar os dados passados: x[n], x[n-1], etc.
    -- Usamos "signed" porque vamos fazer matemática com eles.
    signal x_now  : signed(INPUT_WIDTH - 1 downto 0);
    signal x_reg1 : signed(INPUT_WIDTH - 1 downto 0);
    signal x_reg2 : signed(INPUT_WIDTH - 1 downto 0);
    signal x_reg3 : signed(INPUT_WIDTH - 1 downto 0);
    
    -- Sinal para o resultado final antes de ir para a porta de saída
    signal y_reg  : signed(OUTPUT_WIDTH - 1 downto 0);

begin

    -- 3. O Processo Lógico (Aqui a mágica acontece)
    -- Este processo é "sensível" ao clock e ao reset.
    -- Todo o hardware sequencial (que depende de clock, como Flip-Flops)
    -- DEVE estar dentro de um processo assim.
    REG_PROCESS : process(clk, rst_n)
        -- Variáveis são usadas para cálculos temporários dentro do processo
        -- Elas são mais eficientes para o hardware do que "signals" neste caso
        
        -- Sinais intermediários para as multiplicações (ex: 8 bits * 8 bits = 16 bits)
        variable term0 : signed(INPUT_WIDTH + COEFF_WIDTH - 1 downto 0);
        variable term1 : signed(INPUT_WIDTH + COEFF_WIDTH - 1 downto 0);
        variable term2 : signed(INPUT_WIDTH + COEFF_WIDTH - 1 downto 0);
        variable term3 : signed(INPUT_WIDTH + COEFF_WIDTH - 1 downto 0);
        
        -- Variável para a soma final
        variable y_comb : signed(OUTPUT_WIDTH - 1 downto 0);
    begin
    
        -- Lógica de Reset: Se rst_n for '0', zera tudo.
        if rst_n = '0' then
            x_now  <= (others => '0');
            x_reg1 <= (others => '0');
            x_reg2 <= (others => '0');
            x_reg3 <= (others => '0');
            y_reg  <= (others => '0');
            
        -- Lógica do Clock: O que acontece a cada "batida" do clock
        elsif rising_edge(clk) then
        
            -- ETAPA 1: O REGISTRADOR DE DESLOCAMENTO (SHIFT REGISTER)
            -- Isso move os dados para a próxima posição.
            -- O novo dado (i_data) entra em x_now.
            -- O dado que estava em x_now vai para x_reg1.
            -- O dado que estava em x_reg1 vai para x_reg2.
            -- etc.
            x_now  <= signed(i_data); -- x[n]
            x_reg1 <= x_now;          -- x[n-1]
            x_reg2 <= x_reg1;         -- x[n-2]
            x_reg3 <= x_reg2;         -- x[n-3]
            
            -- ETAPA 2: A MATEMÁTICA (Multiplicação)
            -- Isso acontece de forma combinatória (instantânea)
            -- Note o uso de := para variáveis
            term0 := x_now  * C0; -- b0 * x[n]
            term1 := x_reg1 * C1; -- b1 * x[n-1]
            term2 := x_reg2 * C2; -- b2 * x[n-2]
            term3 := x_reg3 * C3; -- b3 * x[n-3]
            
            -- ETAPA 3: A SOMA
            -- Redimensiona os termos (resize) para o tamanho da saída antes de somar
            y_comb := resize(term0, OUTPUT_WIDTH) + 
                      resize(term1, OUTPUT_WIDTH) + 
                      resize(term2, OUTPUT_WIDTH) + 
                      resize(term3, OUTPUT_WIDTH);
                      
            -- ETAPA 4: REGISTRAR A SAÍDA
            -- O resultado final (y_comb) é guardado no registrador de saída y_reg
            -- Isso faz com que a saída seja limpa e estável, sem "glitches"
            y_reg <= y_comb;
            
        end if;
    end process;

    -- 4. Atribuição Final da Saída
    -- Conecta o nosso registrador de saída interno (y_reg)
    -- à porta de saída do componente (o_data).
    -- Isso é feito fora do processo (combinatório).
    o_data <= std_logic_vector(y_reg);

end architecture rtl;
