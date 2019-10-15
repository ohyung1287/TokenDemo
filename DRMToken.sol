pragma solidity ^0.4.25;
import './ERC721BasicToken.sol';
import './Ownable.sol';


contract DRMToken is ERC721BasicToken, Ownable{
     string public tokenName = "Digital Right Token";
    string public symbol = "DRM";
    struct Artwork{
        string name;
        string artist;
        string description;
        string realart;// link of image 
        string thumbnail;// url image
        uint64 timestamp;
    }
    uint _artworkId = 0;
    uint256[] onStoreTokens;
    Artwork[] public artworks; 
    mapping(uint256 => bool) internal isCreated;
    mapping(address => bool) public registeredArtists;
    mapping(uint256 => uint256) public tokenPrices;
    // mapping(string => uint256[]) public IPFStoID; // filter out a list of ID with same image 
    uint public tokenCount=0;
    function getOnStoreTokens()external view returns(uint256[]){
        return onStoreTokens;
    }
    function artistRegister(address _artist)external onlyOwner{ 
        registeredArtists[_artist] = true;
    }
    function isRegisteredArtist()external returns(bool){
        address sender= msg.sender;
        return registeredArtists[sender];
    }

    // Creates artwork as private token
    // 1. Put attributes in new token
    // 2. Transfer token to the artist
    // the new token will belong to artist directly
    function privateCreation(string _name, string _artist, string _description, string _realart, string _thumbnail, uint _deployNum) public { // When artist upload a new artwork to platform
        require(_deployNum > 0);
        require(registeredArtists[msg.sender]);
        for(uint i=0; i < _deployNum ; i++){
            Artwork memory _artwork = Artwork({
                name:_name,
                artist:_artist,
                description:_description,
                realart:_realart,
                thumbnail:_thumbnail,
                timestamp:uint64(now)
            });
            uint256 id = artworks.push(_artwork) - 1;
            _mint(msg.sender, id);
            isCreated[id] = true;
            tokenCount++; //adds one to total token count
        }
    }
    function publicCreation(uint _price,string _name, string _artist, string _description, string _realart, string _thumbnail, uint _deployNum) public { // When artist upload a new artwork to platform
        require(_deployNum > 0);
        require(registeredArtists[msg.sender]);
        for(uint i=0; i < _deployNum ; i++){
            Artwork memory _artwork = Artwork({
                name:_name,
                artist:_artist,
                description:_description,
                realart:_realart,
                thumbnail:_thumbnail,
                timestamp:uint64(now)
            });
            uint256 id = artworks.push(_artwork) - 1;
            tokenPrices[id] = _price;
            isCreated[id] = true;
            onStoreTokens.push(id);
            tokenCount++; //adds one to total token count
        }
    }
    function publicCreationWithContributor(uint _price, address[] _contribuctors, uint[] _percentages,string _name, string _artist, string _description, string _realart, string _thumbnail, uint _deployNum) public { // When artist upload a new artwork to platform
        require(_deployNum > 0);
        require(registeredArtists[msg.sender]);
        for(uint i=0; i < _deployNum ; i++){
            Artwork memory _artwork = Artwork({
                name:_name,
                artist:_artist,
                description:_description,
                realart:_realart,
                thumbnail:_thumbnail,
                timestamp:uint64(now)
            });
            uint256 id = artworks.push(_artwork) - 1;
            tokenPrices[id] = _price;
            isCreated[id] = true;
        }
    }
    function requestBuy(uint256 _tokenId) payable external ifNotPaused {
        require(msg.value >= tokenPrices[_tokenId]);
        require(isCreated[_tokenId]);
        // require(TokenMint(msg.sender,_tokenId));
        // _artistWallet.transfer(value.div(2));
        uint index=0;
        for(index=0;i<onStoreTokens.length;index++){
            if(onStoreTokens[index] == _tokenId){
                for (uint i = index; i<onStoreTokens.length-1; i++){
                    onStoreTokens[i] = onStoreTokens[i+1];
                }
                delete onStoreTokens[onStoreTokens.length-1];
                onStoreTokens.length--;
            }
        }
        _mint(msg.sender, _tokenId); //Mints the token ID of the newest placeholder structure to that wallet address.
    }
    function totalToken()public returns(uint){
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
    

}