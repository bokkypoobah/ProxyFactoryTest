# ProxyFactory Test

Testing the ProxyFactory contract for cheaper deployment of copies of contracts.

Information from:

* https://www.reddit.com/r/ethereum/comments/6c1jui/delegatecall_forwarders_how_to_save_5098_on/
  * Creating the forwarding contract only costs <50000 gas, regardless of the length of the underlying call
  * Constructor functions are currently not supported, though the mechanism could be expanded with more effort to support constructors.
  * The output length is limited to 4096 bytes
  * Each call to the contract thereafter will cost an additional ~1100 gas (700 DELEGATECALL + 400 memory expansion)
* https://www.reddit.com/r/CryptoDerivatives/comments/6htqva/experiments_in_gas_cost_reduction/
* https://gist.github.com/GNSPS/ba7b88565c947cfd781d44cf469c2ddb
* https://github.com/gnosis/safe-contracts/blob/master/contracts/Proxy.sol
* https://blog.zeppelinos.org/proxy-patterns/
* http://solidity.readthedocs.io/en/v0.4.21/assembly.html

<br />

<br />

(c) BokkyPooBah / Bok Consulting Pty Ltd 2018. The MIT Licence.
