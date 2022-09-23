These are two original smart contracts I deployed on Ethereum Mainnet and some relevant interfaces and libraries that they interact with.


One smart contract I designed from the ground up that can perform arbitrage between any viable decentralized exchanges on a blockchain leveraging capital using Flash Loans. 
The other smart contract performs arbitrage WITHIN any viable exchange on a blockchain utilized Flash Loans to leverage capital.

Each of the smart contracts borrows a Flash Loan from the AAVE lending pool, and then interacts with the router contract of one or many DEX, trades the relevant token path, deposits the profit into my MetaMask wallet, then returns the Flash Loan plus a small fee.
If the opportunity is not profitable it simply reverts.

These smart contracts are connected to a larger Python system, and a Javascript system that identifies the arbitrage and flashloan ammount. I have not posted the code of these Python and Javascript systems, because those systems are currently profitable.
