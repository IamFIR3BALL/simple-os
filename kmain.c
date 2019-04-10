#define BOOT_EXPORT extern "C" __attribute__((visibility("default")))

typedef unsigned short uint16_t;
typedef unsigned char uint8_t;
typedef unsigned int uint32_t;
typedef unsigned long long uint64_t;

uint16_t* g_pTerminalBuffer;
uint8_t g_uTerminalColor;

uint8_t g_uTerminalRow;
uint8_t g_uTerminalColumn;

void clearTerminal()
{
    for(int i = 0; i < 25; i++)
    {
        for(int j = 0; j < 80; j++)
        {
            int idx = i*80 + j;
            g_pTerminalBuffer[idx] = (uint16_t)' ' | 0;
        }
    }
}

void kprint(const char* pMsg)
{
    while(*pMsg)
    {
        if(*pMsg == '\n')
        {
            g_uTerminalColumn = 0;
            g_uTerminalRow++;
            pMsg++;
            continue;
        }
        int idx = g_uTerminalRow*80 + g_uTerminalColumn;
        g_pTerminalBuffer[idx] = (uint16_t)(*pMsg) | g_uTerminalColor << 8;
        pMsg++;
        g_uTerminalColumn++;
        if(g_uTerminalColumn == 80)
        {
            g_uTerminalColumn = 0;
            g_uTerminalRow++;
        }
    }
}

void initTerminal()
{
    g_uTerminalColor = (uint8_t)0xF | (uint8_t)0;
    g_pTerminalBuffer = (uint16_t*)0xc00b8000;
}

BOOT_EXPORT void kmain()
{
    initTerminal();

    clearTerminal();

    kprint("Sosi pis0sTEST\n");
    kprint("test");
    while(true){}
    return;
}
