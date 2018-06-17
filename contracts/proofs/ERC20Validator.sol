pragma solidity ^0.4.23;


import "../mixin/RootChainValidator.sol";
import "../lib/BytesLib.sol";


contract ERC20Validator is RootChainValidator {
  // TODO optimize signatures (gas optimization while deploying the contract)

  // keccak256(0xa9059cbb) = keccak256('transfer(address,uint256)')
  bytes32 constant public transferSignature = 0xabce0605a16ff5e998983a0af570b8ad942bb11e305eb20ae3ada0a3be24eb97;

  // keccak256('Withdraw(address,address,uint256)')
  bytes32 constant public withdrawEventSignature = 0x9b1bfa7fa9ee420a16e124f794c35ac9f90472acc99140eb2f6447c714cad8eb;
  // keccak256('Transfer(address,address,uint256)')
  bytes32 constant public transferEventSignature = 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;
  // keccak256('Approval(address,address,uint256)')
  bytes32 constant public approvalEventSignature = 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;
  // keccak256('LogDeposit(uint256,uint256,uint256)')
  bytes32 constant public logDepositEventSignature = 0xd5f41a4c53ae8d3f972ea59f65a253e16b5fca34ab8e51869011143e11f2ef20;
  // keccak256('LogWithdraw(uint256,uint256,uint256)')
  bytes32 constant public logWithdrawEventSignature = 0x3228bf4a0d547ed34051296b931fce02a1927888b6bc3dfbb85395d0cca1e9e0;
  // keccak256('LogTransfer(uint256,uint256,uint256,uint256)')
  bytes32 constant public logTransferEventSignature = 0xc079d0fae1a127a6cbdf9a66b53306735d9810d328fbb557cb130e62b80433ca;

  // validate ERC20 TX
  function validateERC20TransferTx(
    uint256 headerNumber,
    bytes headerProof,

    uint256 blockNumber,
    uint256 blockTime,
    bytes32 txRoot,
    bytes32 receiptRoot,
    bytes path,

    bytes txBytes,
    bytes txProof,

    bytes receiptBytes,
    bytes receiptProof
  ) public {
    // validate tx receipt existence
    require(validateTxReceiptExistence(
      headerNumber,
      headerProof,
      blockNumber,
      blockTime,
      txRoot,
      receiptRoot,
      path,
      txBytes,
      txProof,
      receiptBytes,
      receiptProof
    ));

    // check transaction
    RLP.RLPItem[] memory items = txBytes.toRLPItem().toList();
    require(items.length == 9);

    // check if child token is mapped with root tokens
    address childToken = items[3].toAddress();
    require(rootChain.reverseTokens(childToken) != address(0));

    // check if transaction is transfer tx
    // <4 bytes transfer event,address (32 bytes),amount (32 bytes)>
    bytes memory dataField = items[5].toData();
    require(keccak256(BytesLib.slice(dataField, 0, 4)) == transferSignature); 

    /*
      check receipt and data field
      Receipt -->
        [0]
        [1]
        [2]
        [3]-> [
          [child token address, [transferEventSignature, from, to], <amount>],
          [child token address, [logTransferEventSignature], <input1,input2,output1,output2>]
        ]
    */
    items = receiptBytes.toRLPItem().toList();
    address sender = getTxSender(txBytes);
    if (
      dataField.length != 68 // check if data field is valid
      || items.length != 4 // check if receipt is valid
      || items[3].toList().length != 2  // check if there are 2 events
      || !_validateTransferEvent(
        childToken,
        sender,
        BytesLib.toAddress(dataField, 16),
        BytesLib.toUint(dataField, 36),
        items[3].toList()[0].toList()
      )
      || !_validateLogTransferEvent(
        childToken,
        sender,
        BytesLib.toAddress(dataField, 16),
        BytesLib.toUint(dataField, 36),
        items[3].toList()[1].toList()
      )
    ) {
      rootChain.slash();
      return;
    }
  }

  function _validateTransferEvent(
    address childToken,
    address from,
    address to,
    uint256 amount,
    RLP.RLPItem[] items // [child token address, [transferEventSignature, from, to], <amount>]
  ) internal view returns (bool) {
    if (items.length != 3) {
      return false;
    }

    RLP.RLPItem[] memory topics = items[1].toList();
    if (
      topics.length == 3
      && items[0].toAddress() == childToken
      && topics[0].toBytes32() == transferEventSignature
      && BytesLib.toAddress(topics[1].toData(), 12) == from
      && BytesLib.toAddress(topics[2].toData(), 12) == to
      && BytesLib.toUint(items[2].toData(), 0) == amount
    ) {
      return true;
    }

    return false;
  }

  function _validateLogTransferEvent(
    address childToken,
    address from,
    address to,
    uint256 amount,
    RLP.RLPItem[] items // [child token address, [logTransferEventSignature], <input1,input2,output1,output2>]
  ) internal view returns (bool) {
    if (items.length != 3) {
      return false;
    }

    uint256 diff = from == to ? 0 : amount;
    RLP.RLPItem[] memory topics = items[1].toList();
    if (
      topics.length == 1
      && items[0].toAddress() == childToken
      && topics[0].toBytes32() == logTransferEventSignature
      && (BytesLib.toUint(items[2].toData(), 0) - BytesLib.toUint(items[2].toData(), 64)) == diff
      && (BytesLib.toUint(items[2].toData(), 96) - BytesLib.toUint(items[2].toData(), 32)) == diff
    ) {
      return true;
    }

    return false;
  }
}