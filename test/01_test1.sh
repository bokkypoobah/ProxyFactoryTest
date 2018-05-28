#!/bin/bash
# ----------------------------------------------------------------------------------------------
# Testing the smart contract
#
# Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
# ----------------------------------------------------------------------------------------------

MODE=${1:-test}

GETHATTACHPOINT=`grep ^IPCFILE= settings.txt | sed "s/^.*=//"`
PASSWORD=`grep ^PASSWORD= settings.txt | sed "s/^.*=//"`

SOURCEDIR=`grep ^SOURCEDIR= settings.txt | sed "s/^.*=//"`

PROXYFACTORYSOL=`grep ^PROXYFACTORYSOL= settings.txt | sed "s/^.*=//"`
PROXYFACTORYJS=`grep ^PROXYFACTORYJS= settings.txt | sed "s/^.*=//"`
TESTCONTRACT1SOL=`grep ^TESTCONTRACT1SOL= settings.txt | sed "s/^.*=//"`
TESTCONTRACT1JS=`grep ^TESTCONTRACT1JS= settings.txt | sed "s/^.*=//"`

DEPLOYMENTDATA=`grep ^DEPLOYMENTDATA= settings.txt | sed "s/^.*=//"`

INCLUDEJS=`grep ^INCLUDEJS= settings.txt | sed "s/^.*=//"`
TEST1OUTPUT=`grep ^TEST1OUTPUT= settings.txt | sed "s/^.*=//"`
TEST1RESULTS=`grep ^TEST1RESULTS= settings.txt | sed "s/^.*=//"`
JSONSUMMARY=`grep ^JSONSUMMARY= settings.txt | sed "s/^.*=//"`
JSONEVENTS=`grep ^JSONEVENTS= settings.txt | sed "s/^.*=//"`

CURRENTTIME=`date +%s`
CURRENTTIMES=`perl -le "print scalar localtime $CURRENTTIME"`
START_DATE=`echo "$CURRENTTIME+45" | bc`
START_DATE_S=`perl -le "print scalar localtime $START_DATE"`
END_DATE=`echo "$CURRENTTIME+60*2" | bc`
END_DATE_S=`perl -le "print scalar localtime $END_DATE"`

printf "MODE               = '$MODE'\n" | tee $TEST1OUTPUT
printf "GETHATTACHPOINT    = '$GETHATTACHPOINT'\n" | tee -a $TEST1OUTPUT
printf "PASSWORD           = '$PASSWORD'\n" | tee -a $TEST1OUTPUT
printf "SOURCEDIR          = '$SOURCEDIR'\n" | tee -a $TEST1OUTPUT
printf "PROXYFACTORYSOL    = '$PROXYFACTORYSOL'\n" | tee -a $TEST1OUTPUT
printf "PROXYFACTORYJS     = '$PROXYFACTORYJS'\n" | tee -a $TEST1OUTPUT
printf "TESTCONTRACT1SOL   = '$TESTCONTRACT1SOL'\n" | tee -a $TEST1OUTPUT
printf "TESTCONTRACT1JS    = '$TESTCONTRACT1JS'\n" | tee -a $TEST1OUTPUT
printf "DEPLOYMENTDATA     = '$DEPLOYMENTDATA'\n" | tee -a $TEST1OUTPUT
printf "INCLUDEJS          = '$INCLUDEJS'\n" | tee -a $TEST1OUTPUT
printf "TEST1OUTPUT        = '$TEST1OUTPUT'\n" | tee -a $TEST1OUTPUT
printf "TEST1RESULTS       = '$TEST1RESULTS'\n" | tee -a $TEST1OUTPUT
printf "JSONSUMMARY        = '$JSONSUMMARY'\n" | tee -a $TEST1OUTPUT
printf "JSONEVENTS         = '$JSONEVENTS'\n" | tee -a $TEST1OUTPUT
printf "CURRENTTIME        = '$CURRENTTIME' '$CURRENTTIMES'\n" | tee -a $TEST1OUTPUT
printf "START_DATE         = '$START_DATE' '$START_DATE_S'\n" | tee -a $TEST1OUTPUT
printf "END_DATE           = '$END_DATE' '$END_DATE_S'\n" | tee -a $TEST1OUTPUT

# Make copy of SOL file and modify start and end times ---
`cp $SOURCEDIR/* .`

# --- Modify parameters ---
# `perl -pi -e "s/START_DATE \= 1525132800.*$/START_DATE \= $START_DATE; \/\/ $START_DATE_S/" $CROWDSALESOL`
# `perl -pi -e "s/endDate \= 1527811200;.*$/endDate \= $END_DATE; \/\/ $END_DATE_S/" $CROWDSALESOL`

DIFFS1=`diff $SOURCEDIR/$PROXYFACTORYSOL $PROXYFACTORYSOL`
echo "--- Differences $SOURCEDIR/$PROXYFACTORYSOL $PROXYFACTORYSOL ---" | tee -a $TEST1OUTPUT
echo "$DIFFS1" | tee -a $TEST1OUTPUT

DIFFS1=`diff $SOURCEDIR/$TESTCONTRACT1SOL $TESTCONTRACT1SOL`
echo "--- Differences $SOURCEDIR/$TESTCONTRACT1SOL $TESTCONTRACT1SOL ---" | tee -a $TEST1OUTPUT
echo "$DIFFS1" | tee -a $TEST1OUTPUT

solc_0.4.24 --version | tee -a $TEST1OUTPUT

echo "var proxyFactoryOutput=`solc_0.4.24 --optimize --pretty-json --combined-json abi,bin,interface $PROXYFACTORYSOL`;" > $PROXYFACTORYJS
echo "var tokenOutput=`solc_0.4.24 --optimize --pretty-json --combined-json abi,bin,interface $TESTCONTRACT1SOL`;" > $TESTCONTRACT1JS


geth --verbosity 3 attach $GETHATTACHPOINT << EOF | tee -a $TEST1OUTPUT
loadScript("$PROXYFACTORYJS");
loadScript("$TESTCONTRACT1JS");
loadScript("functions.js");

var proxyFactoryAbi = JSON.parse(proxyFactoryOutput.contracts["$PROXYFACTORYSOL:ProxyFactory"].abi);
var proxyFactoryBin = "0x" + proxyFactoryOutput.contracts["$PROXYFACTORYSOL:ProxyFactory"].bin;
var tokenAbi = JSON.parse(tokenOutput.contracts["$TESTCONTRACT1SOL:MintableToken"].abi);
var tokenBin = "0x" + tokenOutput.contracts["$TESTCONTRACT1SOL:MintableToken"].bin;

// console.log("DATA: proxyFactoryAbi=" + JSON.stringify(proxyFactoryAbi));
// console.log("DATA: proxyFactoryBin=" + JSON.stringify(proxyFactoryBin));
// console.log("DATA: tokenAbi=" + JSON.stringify(tokenAbi));
// console.log("DATA: tokenBin=" + JSON.stringify(tokenBin));


unlockAccounts("$PASSWORD");
printBalances();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var deployProxyFactoryMessage = "Deploy ProxyFactory";
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + deployProxyFactoryMessage + " ----------");
var proxyFactoryContract = web3.eth.contract(proxyFactoryAbi);
// console.log(JSON.stringify(proxyFactoryContract));
var proxyFactoryTx = null;
var proxyFactoryAddress = null;
var proxyFactory = proxyFactoryContract.new({from: contractOwnerAccount, data: proxyFactoryBin, gas: 6000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        proxyFactoryTx = contract.transactionHash;
      } else {
        proxyFactoryAddress = contract.address;
        addAccount(proxyFactoryAddress, "ProxyFactory");
        addProxyFactoryContractAddressAndAbi(proxyFactoryAddress, proxyFactoryAbi);
        console.log("DATA: proxyFactoryAddress=" + proxyFactoryAddress);
      }
    }
  }
);
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(proxyFactoryTx, deployProxyFactoryMessage);
printTxData("proxyFactoryTx", proxyFactoryTx);
printProxyFactoryContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var deployTokenMessage = "Deploy Token Contract";
var symbol = "ORIGINAL";
var name = "Original";
var decimals = 18;
var initialSupply = new BigNumber("1000000").shift(18);
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + deployTokenMessage + " ----------");
var tokenContract = web3.eth.contract(tokenAbi);
// console.log(JSON.stringify(tokenContract));
var tokenTx = null;
var tokenAddress = null;
var token = tokenContract.new({from: contractOwnerAccount, data: tokenBin, gas: 6000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        tokenTx = contract.transactionHash;
      } else {
        tokenAddress = contract.address;
      }
    }
  }
);
while (txpool.status.pending > 0) {
}
var deployToken_1Tx = token.init(symbol, name, decimals, contractOwnerAccount, initialSupply, {from: contractOwnerAccount, data: tokenBin, gas: 6000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
addAccount(tokenAddress, "Token '" + token.symbol() + "' '" + token.name() + "'");
addTokenAContractAddressAndAbi(tokenAddress, tokenAbi);
console.log("DATA: var tokenAddress=\"" + tokenAddress + "\";");
console.log("DATA: var tokenAbi=" + JSON.stringify(tokenAbi) + ";");
console.log("DATA: var token=eth.contract(tokenAbi).at(tokenAddress);");
printBalances();
failIfTxStatusError(tokenTx, deployTokenMessage + " - deploy");
failIfTxStatusError(deployToken_1Tx, deployTokenMessage + " - init");
printTxData("tokenTx", tokenTx);
printTxData("deployToken_1Tx", deployToken_1Tx);
printTokenAContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var deployProxyContractMessage = "Deploy Proxy Contract";
// var originalData = "00000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000012000000000000000000000000a11aae29840fbb5c86e6fd4cf809eba183aef43300000000000000000000000000000000000000000000d3c21bcecceda100000000000000000000000000000000000000000000000000000000000000000000074f5247494e414c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000084f726967696e616c000000000000000000000000000000000000000000000000";
// console.log("RESULT: originalData=" + originalData);
// var tokenContract=eth.contract(tokenAbi);
// var data="0x" + tokenContract.new.getData(symbol, name, decimals, contractOwnerAccount, initialSupply.toFixed(0)).substring(9);
var data="";
// console.log("RESULT: data=" + data);
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + deployProxyContractMessage + " -----");
var deployProxyContractTx = proxyFactory.createProxy(tokenAddress, data, {from: aliceAccount, gas: 4000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
var newContractAddress = getProxyFactoryListing();
console.log("RESULT: newContractAddress=" + newContractAddress);
var newToken = web3.eth.contract(tokenAbi).at(newContractAddress);
var symbol = "NEWTOKEN";
var name = "New Token";
var decimals = 18;
var initialSupply = new BigNumber("2000000").shift(18);
var deployNewToken_1Tx = newToken.init(symbol, name, decimals, aliceAccount, initialSupply, {from: aliceAccount, data: tokenBin, gas: 6000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
addAccount(newContractAddress, "New Token '" + newToken.symbol() + "' '" + newToken.name() + "'");
addTokenBContractAddressAndAbi(newContractAddress, tokenAbi);
printBalances();
failIfTxStatusError(deployProxyContractTx, deployProxyContractMessage + " - Deploy New Token Contract");
failIfTxStatusError(deployNewToken_1Tx, deployProxyContractMessage + " - New Token Contract Init");
printTxData("deployProxyContractTx", deployProxyContractTx);
printTxData("deployNewToken_1Tx", deployNewToken_1Tx);
printProxyFactoryContractDetails();
printTokenAContractDetails();
printTokenBContractDetails();
console.log("RESULT: ");


console.log("RESULT: oldAddr=" + tokenAddress);
console.log("RESULT: newAddr=" + newContractAddress);
console.log("RESULT: oldCode=" + eth.getCode(tokenAddress));
console.log("RESULT: newCode=" + eth.getCode(newContractAddress));

for (var i = 0; i < 10; i++) {
  var older = eth.getStorageAt(tokenAddress, i);
  var newer = eth.getStorageAt(newContractAddress, i);
  var olderText;
  var newerText;
  if (i == 2 || i == 3) {
    olderText = web3.toAscii(older.replace(/00.*$/g,""));
    newerText = web3.toAscii(newer.replace(/00.*$/g,""));
  } else {
    olderText = "";
    newerText = "";
  }
  console.log("RESULT: old data[" + i + "]=" + older + " " + new BigNumber(older.substring(2), 16) + " " + olderText);
  console.log("RESULT: new data[" + i + "]=" + newer + " " + new BigNumber(newer.substring(2), 16) + " " + newerText);
}

var oldBalanceKey = web3.sha3("000000000000000000000000" + contractOwnerAccount.substring(2) + "0000000000000000000000000000000000000000000000000000000000000007", {"encoding":"hex"});
var older = eth.getStorageAt(tokenAddress, oldBalanceKey);
console.log("RESULT: mapping(olderKey,7)=" + older + " " + new BigNumber(older.substring(2), 16));

var newBalanceKey = web3.sha3("000000000000000000000000" + aliceAccount.substring(2) + "0000000000000000000000000000000000000000000000000000000000000007", {"encoding":"hex"});
var newer = eth.getStorageAt(newContractAddress, newBalanceKey);
console.log("RESULT: mapping(newerKey,7)=" + newer + " " + new BigNumber(newer.substring(2), 16));

EOF
grep "DATA: " $TEST1OUTPUT | sed "s/DATA: //" > $DEPLOYMENTDATA
cat $DEPLOYMENTDATA
grep "RESULT: " $TEST1OUTPUT | sed "s/RESULT: //" > $TEST1RESULTS
cat $TEST1RESULTS