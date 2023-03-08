const HDWalletProvider = require('@truffle/hdwallet-provider');

// 2. Moonbeam development node private key
const privateKeyDev =
   '';

module.exports = {
  /**
   * Networks define how you connect to your ethereum client and let you set the
   * defaults web3 uses to send transactions. If you don't specify one truffle
   * will spin up a development blockchain for you on port 9545 when you
   * run `develop` or `test`. You can ask a truffle command to use a specific
   * network from the command line, e.g
   *
   * $ truffle test --network <network-name>
   */
  api_keys: {
    arbiscan: ''
  },

  networks: {
    prod: {
      provider: () => {      
        return new HDWalletProvider(privateKeyDev, 'https://arb1.arbitrum.io/rpc')
      },
      network_id: 42161,  
      gasPrice: 101963000
    },
    ropsten: {
      provider: () => {      
        return new HDWalletProvider(privateKeyDev, 'https://ropsten.infura.io/v3/7db028a69a874fac9e989c481cbc8784')
      },
      network_id: 3,  
      gasPrice: 470000000
    },
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.7.6",
      settings: {    
       optimizer: {
         enabled: true,
         runs: 200,
         details: {
          cse: true,
          constantOptimizer: true,
          yul: true,
          deduplicate: true
         }
       },
      }
    },
  },
  plugins: ['truffle-plugin-stdjsonin','truffle-plugin-verify']
};
