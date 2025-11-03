# fpga-low-latency-market-feed
PGA learning project to build a real‑time market‑data handler: simulate UDP packets with symbol, price and volume; parse them in hardware (Ethernet → IP → UDP → payload); and issue a “BUY” trigger when the price crosses a threshold—measuring deterministic hardware latency and comparing it to a software baseline.
