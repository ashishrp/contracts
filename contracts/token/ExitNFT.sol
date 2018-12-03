pragma solidity ^0.4.24;

import { ERC721 } from "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";

import { ERC721Full } from "openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import { ERC721Mintable } from "openzeppelin-solidity/contracts/token/ERC721/ERC721Mintable.sol";
import { ERC721Burnable } from "openzeppelin-solidity/contracts/token/ERC721/ERC721Burnable.sol";

import { RootChainable } from "../mixin/RootChainable.sol";


contract ExitNFT is RootChainable, ERC721Full, ERC721Mintable, ERC721Burnable {
  constructor(string _name, string _symbol) public ERC721Full(_name, _symbol) {

  }
 
  // function mint(address _owner, uint256 _tokenId) public onlyRootChain returns (bool)  {
  //   return _mint(_owner, _tokenId);
  // }

  function burnFrom(address _owner, uint256 _tokenId) public onlyRootChain {
    _burn(_owner, _tokenId);
  }

}

