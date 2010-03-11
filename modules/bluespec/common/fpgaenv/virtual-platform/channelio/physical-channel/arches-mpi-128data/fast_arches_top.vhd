library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity fast_arches_top is
    generic
    (
        C_EXT_RESET_HIGH    : integer := 1;
        C_CMD_VECTOR_WIDTH  : integer := 72;
        C_DATA_VECTOR_WIDTH : integer := 128;
        C_VECTOR_SIZE       : integer := 1024
    );
    port
    (
        Math_error          : out std_logic;
        Buffer_error        : out std_logic;
        Instr_error         : out std_logic;

        -- Clock and reset signals 
        Clk                 : in  std_logic;
        Rst                 : in  std_logic;

        -- FSL Interfaces 
        To_mpe_cmd_data     : out std_logic_vector(C_CMD_VECTOR_WIDTH-1 downto 0);
        To_mpe_cmd_ctrl     : out std_logic;
        To_mpe_cmd_write    : out std_logic;
        To_mpe_cmd_full     : in  std_logic;

        From_mpe_cmd_data   : in  std_logic_vector(C_CMD_VECTOR_WIDTH-1 downto 0);
        From_mpe_cmd_ctrl   : in  std_logic;
        From_mpe_cmd_exists : in  std_logic;
        From_mpe_cmd_read   : out std_logic;

        To_mpe_data_data    : out std_logic_vector(C_DATA_VECTOR_WIDTH-1 downto 0);
        To_mpe_data_ctrl    : out std_logic;
        To_mpe_data_write   : out std_logic;
        To_mpe_data_full    : in  std_logic;

        From_mpe_data_data  : in  std_logic_vector(C_DATA_VECTOR_WIDTH-1 downto 0);
        From_mpe_data_ctrl  : in  std_logic;
        From_mpe_data_exists: in  std_logic;
        From_mpe_data_read  : out std_logic
       
    );
end;


architecture Behavioral of fast_arches_top is

    component mkTopArches is
        port
        (
            -- Clock and reset signals 
            CLK                 : in  std_logic;
            RST_N               : in  std_logic;

            -- FSL Interfaces 
            mpe_cmd_to_fsl_data     : out std_logic_vector(C_CMD_VECTOR_WIDTH-1 downto 0);
            mpe_cmd_to_fsl_ctrl     : out std_logic;
            mpe_cmd_to_fsl_write    : out std_logic;
            mpe_cmd_to_fsl_full     : in  std_logic;

            mpe_cmd_from_fsl_data   : in  std_logic_vector(C_CMD_VECTOR_WIDTH-1 downto 0);
            mpe_cmd_from_fsl_ctrl   : in  std_logic;
            mpe_cmd_from_fsl_exists : in  std_logic;
            mpe_cmd_from_fsl_read   : out std_logic;

            mpe_data_to_fsl_data    : out std_logic_vector(C_DATA_VECTOR_WIDTH-1 downto 0);
            mpe_data_to_fsl_ctrl    : out std_logic;
            mpe_data_to_fsl_write   : out std_logic;
            mpe_data_to_fsl_full    : in  std_logic;

            mpe_data_from_fsl_data  : in  std_logic_vector(C_DATA_VECTOR_WIDTH-1 downto 0);
            mpe_data_from_fsl_ctrl  : in  std_logic;
            mpe_data_from_fsl_exists: in  std_logic;
            mpe_data_from_fsl_read  : out std_logic
           
        );
    end component mkTopArches;

    signal rstn : std_logic;

begin

    TOP : mkTopArches
    port map
    (
            -- Clock and reset signals 
            CLK                 => Clk,
            RST_N               => rstn,

            -- FSL Interfaces 
            mpe_cmd_to_fsl_data      => To_mpe_cmd_data,
            mpe_cmd_to_fsl_ctrl      => To_mpe_cmd_ctrl,
            mpe_cmd_to_fsl_write     => To_mpe_cmd_write,
            mpe_cmd_to_fsl_full      => To_mpe_cmd_full,

            mpe_cmd_from_fsl_data    => From_mpe_cmd_data,
            mpe_cmd_from_fsl_ctrl    => From_mpe_cmd_ctrl,
            mpe_cmd_from_fsl_exists  => From_mpe_cmd_exists,
            mpe_cmd_from_fsl_read    => From_mpe_cmd_read,

            mpe_data_to_fsl_data     => To_mpe_data_data,
            mpe_data_to_fsl_ctrl     => To_mpe_data_ctrl,
            mpe_data_to_fsl_write    => To_mpe_data_write,
            mpe_data_to_fsl_full     => To_mpe_data_full,

            mpe_data_from_fsl_data   => From_mpe_data_data,
            mpe_data_from_fsl_ctrl   => From_mpe_data_ctrl,
            mpe_data_from_fsl_exists => From_mpe_data_exists,
            mpe_data_from_fsl_read   => From_mpe_data_read
    );

    -- Reset polarity
    process (Rst) is
    begin
        if C_EXT_RESET_HIGH = 1 then
            rstn <= not Rst;
        else
            rstn <= Rst;
        end if;
    end process;

    Math_error   <= '0';
    Buffer_error <= '0';
    Instr_error  <= '0';

end;

