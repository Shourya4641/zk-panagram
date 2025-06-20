// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IVerifier} from "src/Verifier.sol";

contract MockVerifier is IVerifier {
    bool private shouldReturnTrue;
    
    constructor() {
        shouldReturnTrue = true;
    }
    
    function verify(bytes memory, bytes32[] memory) external view override returns (bool) {
        return shouldReturnTrue;
    }
    
    function setShouldReturnTrue(bool _value) external {
        shouldReturnTrue = _value;
    }
}