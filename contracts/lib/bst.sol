pragma solidity ^0.4.24;

import { Math } from "openzeppelin-solidity/contracts/math/Math.sol";

// basic array indexing based bst implementation 
contract Bst {
  struct Node {
    uint256 value;
    uint256 left;
    uint256 right;
  }
  
  Node[] tree;
  uint256 root;
  uint256 count = 0;
  
  constructor() public {
    root = 0;
    tree.push(node(0,0,0));
  }
   
  function insert(uint256 value) returns(uint256){
    if (root == 0) {
      root = 1;
      tree.push(node({
      value : value,
      left : 0,
      right : 0
      }));
    } else {
      return _insert(root, value);
    }
    return root;
  }
  
  function search(uint256 value) returns(uint256){
      return _search(root,value);
  }
  
  function _insert(uint256 r, uint256 value) private returns (uint256) {
      if (tree[r].value > value) {
          if(tree[r].left==0){
            tree[r].left = tree.length;
            tree.push(node(value,0,0));
            return tree[r].left;
          } else {
              return _insert(tree[r].left, value);
          }
      } else {
          if (tree[r].right == 0) {
            tree[r].right = tree.length;
            tree.push(node(value,0,0));
            return tree[r].right;
          } else {
              return _insert(tree[r].right, value);
          }
      }
  }

  function _search(uint256 r, uint256 value) private returns(uint256){
   if (r == 0) {
       return 0;
   }

   if (tree[r].value == value) {
       return tree[r].right;
   }

   if (tree[r].value > value) {
       return _search(tree[r].left, value);
   } else {
       return _search(tree[r].right, value);
    }
  }

}