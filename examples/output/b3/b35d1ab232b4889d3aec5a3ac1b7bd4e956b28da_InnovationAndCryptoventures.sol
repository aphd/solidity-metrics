pragma solidity ^0.5.0; 
contract InnovationAndCryptoventures {
    string[] hashes;
    string[] groups = [&quot;A1&quot;,&quot;A2&quot;,&quot;A3&quot;,&quot;A4&quot;,&quot;A5&quot;,&quot;A6&quot;,&quot;A7&quot;,&quot;A8&quot;,&quot;A9&quot;,&quot;A10&quot;,&quot;A11&quot;,&quot;A12&quot;,&quot;A13&quot;,&quot;A14&quot;,&quot;A15&quot;,&quot;A16&quot;,&quot;A17&quot;,&quot;A18&quot;,&quot;A19&quot;,&quot;A20&quot;,&quot;B1&quot;,&quot;B2&quot;,&quot;B3&quot;,&quot;B4&quot;,&quot;B5&quot;,&quot;B6&quot;,&quot;B7&quot;,&quot;B8&quot;,&quot;B9&quot;,&quot;B10&quot;,&quot;B11&quot;,&quot;B12&quot;,&quot;B13&quot;,&quot;B14&quot;,&quot;B15&quot;,&quot;B16&quot;,&quot;B17&quot;,&quot;B18&quot;,&quot;B19&quot;,&quot;B20&quot;,&quot;C1&quot;,&quot;C2&quot;,&quot;C3&quot;,&quot;C4&quot;,&quot;C5&quot;,&quot;C6&quot;,&quot;C7&quot;,&quot;C8&quot;,&quot;C9&quot;,&quot;C10&quot;,&quot;C11&quot;,&quot;C12&quot;,&quot;C13&quot;,&quot;C14&quot;,&quot;C15&quot;,&quot;C16&quot;,&quot;C17&quot;,&quot;C18&quot;,&quot;C19&quot;,&quot;C20&quot;];
    
    mapping(uint=>mapping(int=>string)) yearToGroupToHash;

    mapping(string=>uint) hashToYear;
    mapping(string=>int) hashToGroup;
    
    event A1(uint year, string hash);
    event A2(uint year, string hash);
    event A3(uint year, string hash);
    event A4(uint year, string hash);
    event A5(uint year, string hash);
    event A6(uint year, string hash);
    event A7(uint year, string hash);
    event A8(uint year, string hash);
    event A9(uint year, string hash);
    event A10(uint year, string hash);
    event A11(uint year, string hash);
    event A12(uint year, string hash);
    event A13(uint year, string hash);
    event A14(uint year, string hash);
    event A15(uint year, string hash);
    event A16(uint year, string hash);
    event A17(uint year, string hash);
    event A18(uint year, string hash);
    event A19(uint year, string hash);
    event A20(uint year, string hash);
    
    event B1(uint year, string hash);
    event B2(uint year, string hash);
    event B3(uint year, string hash);
    event B4(uint year, string hash);
    event B5(uint year, string hash);
    event B6(uint year, string hash);
    event B7(uint year, string hash);
    event B8(uint year, string hash);
    event B9(uint year, string hash);
    event B10(uint year, string hash);
    event B11(uint year, string hash);
    event B12(uint year, string hash);
    event B13(uint year, string hash);
    event B14(uint year, string hash);
    event B15(uint year, string hash);
    event B16(uint year, string hash);
    event B17(uint year, string hash);
    event B18(uint year, string hash);
    event B19(uint year, string hash);
    event B20(uint year, string hash);
     
    event C1(uint year, string hash);
    event C2(uint year, string hash);
    event C3(uint year, string hash);
    event C4(uint year, string hash);
    event C5(uint year, string hash);
    event C6(uint year, string hash);
    event C7(uint year, string hash);
    event C8(uint year, string hash);
    event C9(uint year, string hash);
    event C10(uint year, string hash);
    event C11(uint year, string hash);
    event C12(uint year, string hash);
    event C13(uint year, string hash);
    event C14(uint year, string hash);
    event C15(uint year, string hash);
    event C16(uint year, string hash);
    event C17(uint year, string hash);
    event C18(uint year, string hash);
    event C19(uint year, string hash);
    event C20(uint year, string hash);

    function publishDeck(uint year, string memory group, string memory hash) public {
        int g = groupIndex(group);
        require(g>=0);
        yearToGroupToHash[year][g] = hash;
        hashToYear[hash] = year;
        hashToGroup[hash] = g;
        
        hashes.push(hash);
        emitHash(year, g, hash);
    }
    
    function emitHash(uint year, int group, string memory hash) internal {
        
        if(group==0) emit A1(year,hash);
        if(group==1) emit A2(year,hash);
        if(group==2) emit A3(year,hash);
        if(group==3) emit A4(year,hash);
        if(group==4) emit A5(year,hash);
        if(group==5) emit A6(year,hash);
        if(group==6) emit A7(year,hash);
        if(group==7) emit A8(year,hash);
        if(group==8) emit A9(year,hash);
        if(group==9) emit A10(year,hash);
        if(group==10) emit A11(year,hash);
        if(group==11) emit A12(year,hash);
        if(group==12) emit A13(year,hash);
        if(group==13) emit A14(year,hash);
        if(group==14) emit A15(year,hash);
        if(group==15) emit A16(year,hash);
        if(group==16) emit A17(year,hash);
        if(group==17) emit A18(year,hash);
        if(group==18) emit A19(year,hash);
        if(group==19) emit A20(year,hash);
        
        if(group==20) emit B1(year,hash);
        if(group==21) emit B2(year,hash);
        if(group==22) emit B3(year,hash);
        if(group==23) emit B4(year,hash);
        if(group==24) emit B5(year,hash);
        if(group==25) emit B6(year,hash);
        if(group==26) emit B7(year,hash);
        if(group==27) emit B8(year,hash);
        if(group==28) emit B9(year,hash);
        if(group==29) emit B10(year,hash);
        if(group==30) emit B11(year,hash);
        if(group==31) emit B12(year,hash);
        if(group==32) emit B13(year,hash);
        if(group==33) emit B14(year,hash);
        if(group==34) emit B15(year,hash);
        if(group==35) emit B16(year,hash);
        if(group==36) emit B17(year,hash);
        if(group==37) emit B18(year,hash);
        if(group==38) emit B19(year,hash);
        if(group==39) emit B20(year,hash);

        if(group==40) emit C1(year,hash);
        if(group==41) emit C2(year,hash);
        if(group==42) emit C3(year,hash);
        if(group==43) emit C4(year,hash);
        if(group==44) emit C5(year,hash);
        if(group==45) emit C6(year,hash);
        if(group==46) emit C7(year,hash);
        if(group==47) emit C8(year,hash);
        if(group==48) emit C9(year,hash);
        if(group==49) emit C10(year,hash);
        if(group==50) emit C11(year,hash);
        if(group==51) emit C12(year,hash);
        if(group==52) emit C13(year,hash);
        if(group==53) emit C14(year,hash);
        if(group==54) emit C15(year,hash);
        if(group==55) emit C16(year,hash);
        if(group==56) emit C17(year,hash);
        if(group==57) emit C18(year,hash);
        if(group==58) emit C19(year,hash);
        if(group==59) emit C20(year,hash);
    }
    
    function groupIndex(string memory group) public view  returns(int){
        bytes32 g = keccak256(abi.encode(group));
        int len = (int) (groups.length);
        for(int i=0;i<len;i++){
            uint j = (uint) (i);
            bytes32 temp = keccak256(abi.encode(groups[j]));
            if(g == temp){
                return i;
            }
        }
        return -1;
    }
    
    function checkExists(string memory hash) public view returns(bool){
        bytes32 h = keccak256(abi.encode(hash));
        for(uint i=0;i<hashes.length;i++){
            bytes32 temp = keccak256(abi.encode(hashes[i]));
            if(h == temp){
                return true;
            }
        }
        return false;
    }
    
    function _checkExists(uint year, int group) public view returns(bool){
        bytes32 n = keccak256(abi.encode(_getHash(0,0)));
        return n != keccak256(abi.encode(_getHash(year,group)));
    }
    
    function checkExists(uint year, string memory group) public view  returns(bool){
        int g = groupIndex(group);
        return _checkExists(year,g);
    }
    
    // Section A=0, B=1, C=2
    function batchEmit(uint year,int section) public {
        require(section>=0 && section<=2);
        for(int i=section*20;i<(section+1)*20;i++){
            if(_checkExists(year,i)){
                string memory hash = _getHash(year,i);
                emitHash(year,i,hash);
            }
        }
    }
    
    function getHash(uint year, string memory group) public view returns(string memory){
        int _group = groupIndex(group);
        return _getHash(year, _group);
    }
    
    function _getHash(uint _year, int _group) public view returns(string memory){
        return yearToGroupToHash[_year][_group];  
    }
    
    function getYear(string memory hash) public view returns(uint){
        return hashToYear[hash]; 
    }
    
    function getGroupString(string memory hash) public view returns(string memory){
        uint g = (uint) (getGroup(hash));
        return groups[g]; 
    }
    
    function getGroup(string memory hash) public view returns(int){
        return hashToGroup[hash];
    }
}