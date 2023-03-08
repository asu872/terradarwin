const DarwinArtifact = artifacts.require('./Darwin.sol');
const DarwinProxyArtifact = artifacts.require('./DarwinProxy.sol');
const ArmoryArtifact = artifacts.require('./Armory.sol');
const Darwin1155Artifact = artifacts.require('./Darwin1155.sol');
const CharacterArtifact = artifacts.require('./Character.sol');
const AvatarArtifact = artifacts.require('./Avatar.sol');
const AvatarProxyArtifact = artifacts.require('./AvatarProxy.sol');




module.exports = async(deployer) => {
//	await deployer.deploy(AvatarProxyArtifact, "0xD2a35D77CE5Deb79ebB8A86e4979124312346e0A","Survivor","SURVIVOR");   
	await deployer.deploy(AvatarArtifact, "0xD2a35D77CE5Deb79ebB8A86e4979124312346e0A","Survivor","SURVIVOR");   
//	await deployer.deploy(DarwinArtifact);   
//	await deployer.deploy(DarwinProxyArtifact);   
// 	await deployer.deploy(ArmoryArtifact, "Darwin Armory","ARMS");   
//	await deployer.deploy(Darwin1155Artifact, "ipfs://");   
//	await deployer.deploy(CharacterArtifact,"Darwin Character","ROLE");   
}