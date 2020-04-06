# generalized-aave-flashloans
Generalized Aave Flashloans

Use [upgradable smart proxy contracts (EIP1167)](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1167.md) in conjunction with flashloans!


# Getting started
```bash
# Install dependencies
npm install -g ganache-cli truffle mocha
npm install

# Run ganache in a separate terminal
ganache-cli -f https://mainnet.infura.io/v3/<API_KET> -d

# Deploy contract
truffle migrate --reset --network development

# Run test
mocha

# BONUS see program execution flow
truffle debug <TX_HASH>
```
