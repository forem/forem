#pragma once

#ifdef DEBUG
#define DBG_PRINT(msg, arg...) printf("%s:%u: " msg "\n", __FUNCTION__, __LINE__, arg);
#else
#define DBG_PRINT(msg, arg...) ((void)0);
#endif
