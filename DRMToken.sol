pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;
import './ERC721BasicToken.sol';
import './Ownable.sol';
import './Strings.sol';
import './Array256Lib.sol';
import "./SafeMath.sol";
contract DRMToken is ERC721BasicToken, Ownable{
    string public tokenName = "Digital Right Token";
    string public symbol = "DRM";
    using Strings for string;
    using Array256Lib for uint256[];
    using SafeMath for uint256;
    struct Artwork{
        string name;
        string artist;
        string description;
        string realart;// link of image 
        string thumbnail;// url image
        uint64 timestamp;
        string[] constraint;// what groups can accesses this token
    }
    uint _artworkId = 1;
    uint256[] onStoreTokens;
    Artwork[] public artworks; 
    mapping(uint256 => bool) internal isCreated;
    mapping(address => bool) public registeredArtists;
    mapping(uint256 => uint256) public tokenPrices;
    mapping(uint256 => address[]) public tokenToArtists;
    mapping(uint256 => uint256[]) public tokenToProfitShare;
    //indicate where this user from, call "addToWhiteList" on front-end
    //and wallet address will be register in whitelist 
    //e.g. ['school'=>{'a','c','e'},'business'=>{'b','d','f'}]
    mapping(string => address[]) private userWhiteList;
    // mapping(string => uint256[]) public IPFStoID; // filter out a list of ID with same image 
    uint public tokenCount=0;
    function addToWhiteList(address _user, string _catalog)alreadyInWhiteList(_user,_catalog) onlyOwner external{
        userWhiteList[_catalog].push(_user);
    }
    modifier alreadyInWhiteList(address _user,string _catalog){
        address[] list = userWhiteList[_catalog];
        for(uint i=0;i<list.length;i++){
            if(list[i]==_user){
                return;
            }
        }
        _;
    }
    function checkWhiteList(string _catalog)external view returns(address[]){
        return userWhiteList[_catalog];
    }
    function getOnStoreTokens()external view returns(uint256[]){
        return onStoreTokens;
    }
    function artistRegister(address _artist)external onlyOwner{
        registeredArtists[_artist] = true;
    }
    function isRegisteredArtist()external view returns(bool){
        address sender= msg.sender;
        return registeredArtists[sender];
    }

    //0.name 1.artist 2.desc 3.realart 4.thumbnail
    function tokenGenerate(address[] _contribuctors,uint[]_precentages,string memory _constraints,uint _price,string[]_metadata , uint _deployNum) onlyOwner { // When artist upload a new artwork to platform
        require(_deployNum > 0);
        string[] memory conarr;
        if(!_constraints.compareTo(""))
            conarr = _constraints.split(",");
        for(uint i=0; i < _deployNum ; i++){
            Artwork memory _artwork = Artwork({
                name:_metadata[0],
                artist:_metadata[1],
                description:_metadata[2],
                realart:_metadata[3],
                thumbnail:_metadata[4],
                timestamp:uint64(now),
                constraint:conarr
            });
            uint256 id = artworks.push(_artwork) - 1;
            tokenPrices[id] = _price;
            isCreated[id] = true;
            onStoreTokens.push(id);
            tokenCount++; //adds one to total token count
            tokenToArtists[id]=_contribuctors;
            if(_precentages.length!=0)
                tokenToProfitShare[id]=_precentages;
            else
                tokenToProfitShare[id]=[10];
        }
    }

    function requestBuy(uint256 _tokenId) payable external ifNotPaused inWhiteList(msg.sender,_tokenId){
        require(msg.value >= tokenPrices[_tokenId]);
        require(isCreated[_tokenId]);
        // profit share
        // tokenToArtists, tokenToProfitShare
        for(uint i=0;i<tokenToArtists[_tokenId].length;i++){
            uint value = msg.value.div(10);
            value = value.mul(tokenToProfitShare[_tokenId][i]);
            address artist = tokenToArtists[_tokenId][i];
            artist.transfer(value);
        }
        // profit share
        var (isOnstore,index) = onStoreTokens.indexOf(_tokenId,true);
        if(isOnstore){
            for (i = index; i<onStoreTokens.length-1; i++){
                onStoreTokens[i] = onStoreTokens[i+1];
            }
            delete onStoreTokens[onStoreTokens.length-1];
            onStoreTokens.length--;
            _mint(msg.sender, _tokenId); //Mints the token ID of the newest placeholder structure to that wallet address.
        }
    }
    function totalToken()public view returns(uint){
        return tokenCount;
    }
    
    function tokensOwned(address _owner) external view returns(uint256[] TokensOwned) {
        uint256 CountOfTokens = balanceOf(_owner);   //stores the total number of tokens that are owned by the "_owner" address

        if (CountOfTokens == 0) {                    //checks to see if the count of tokens is at zero
            return new uint256[](0);                  // function returns an empty array of the above if statement returns true  
        } else {
            uint256[] memory result = new uint256[](CountOfTokens); //allocating memory in the result array to the count of possible owned marbles by the "_owner"
            uint256 totalMarbles = tokenCount;             //setting totalMarbles to the highest marble ID. This is done to keep the value constant when used in the for loop.
            uint256 resultIndex = 0;                                 //initializing resultIndex at 0
            uint256 tokenId;                                        //initializing MarbleId to use later in the for loop 
            for (tokenId = 1; tokenId <= totalMarbles; tokenId++) { //MarbleId gets intialized at 1, the loop will keep going till MarbleId is higher than the total number of Marbles. Adds 1 to MarbleId each loop cycle
                if (tokenOwner[tokenId] == _owner) { //uses TokenOwner mapping from ERC721BasicToken contract, returns true if MarbleId was mapped to "_owner" address
                    result[resultIndex] = tokenId;   //stores the MarbleId in a array of uint256 called result, uses resultIndex to expand the array
                    resultIndex++;                    //add one to resultIdex
                }
                if (CountOfTokens == resultIndex){   //returns the function early when the result count is equal to the total owner's marbles.
                    return result;
                }
            }                                         
            return result;                            //returns an array of MarbleIds
        }
    }
    modifier isAuthorizedArtist(address[] artists){
     for(uint i=0;i<artists.length;i++){
         if(!registeredArtists[artists[i]])
            return;
     }
     _;
    }
    function isWhiteList(address _user,uint _tokenId)public view returns(bool){
        string[] memory constraints = artworks[_tokenId].constraint;
        if(constraints.length==0)
            return true;
        for(uint i=0;i<constraints.length;i++){
            address[]whitelist = userWhiteList[constraints[i]];
            for(uint j=0;j<whitelist.length;j++){
                if(whitelist[j]==_user){
                    return true;
                }
            }
        }
        return false;
    }
    modifier inWhiteList(address _user,uint _tokenId){
        
        string[] memory constraints = artworks[_tokenId].constraint;
        if(constraints.length==0)
            _;
        for(uint i=0;i<constraints.length;i++){
            address[]whitelist = userWhiteList[constraints[i]];
            for(uint j=0;j<whitelist.length;j++){
                if(whitelist[j]==_user){
                    _;
                }
            }
        }
    }

}