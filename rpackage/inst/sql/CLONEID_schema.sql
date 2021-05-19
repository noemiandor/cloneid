-- MySQL dump 10.13  Distrib 8.0.17, for macos10.14 (x86_64)
--
-- Host: cloneredesign.cswgogbb5ufg.us-east-1.rds.amazonaws.com    Database: CLONEID
-- ------------------------------------------------------
-- Server version	5.7.22-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `CellLinesAndPatients`
--

DROP TABLE IF EXISTS `CellLinesAndPatients`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `CellLinesAndPatients` (
  `name` varchar(20) NOT NULL,
  `doublingTime_hours` int(11) DEFAULT NULL,
  `year_of_first_report` int(11) DEFAULT NULL,
  `whichType` enum('cell line','patient') DEFAULT NULL,
  `source` varchar(400) DEFAULT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `CellSurfaceMarkers_hg19`
--

DROP TABLE IF EXISTS `CellSurfaceMarkers_hg19`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `CellSurfaceMarkers_hg19` (
  `hgnc_symbol` varchar(20) NOT NULL,
  `ensembl_gene_id` varchar(20) DEFAULT NULL,
  `entrezgene` int(11) DEFAULT NULL,
  `affy_hg_u133a` varchar(20) DEFAULT NULL,
  `chr` int(11) DEFAULT NULL,
  `startpos` int(11) DEFAULT NULL,
  `endpos` int(11) DEFAULT NULL,
  `Gene` varchar(20) DEFAULT NULL,
  `Gene_synonym` varchar(160) DEFAULT NULL,
  `Ensembl` varchar(20) DEFAULT NULL,
  `Gene_description` varchar(90) DEFAULT NULL,
  `Protein_class` varchar(231) DEFAULT NULL,
  `Evidence` varchar(30) DEFAULT NULL,
  `Antibody` varchar(70) DEFAULT NULL,
  `Reliability_IH` varchar(20) DEFAULT NULL,
  `Reliability_IF` varchar(20) DEFAULT NULL,
  `Subcellular_location` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`hgnc_symbol`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Flask`
--

DROP TABLE IF EXISTS `Flask`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Flask` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `manufacturer` varchar(40) DEFAULT NULL,
  `material` enum('Polystyrene','Polyethylene Terephthalate') DEFAULT NULL,
  `dishSurfaceArea_cm2` float DEFAULT NULL,
  `surface_treated_type` enum('Not Treated','TC-treated','Ultra Low Attachment','Amine','Carboxyl','Fibronectin','Collagen','Gelatin') DEFAULT NULL,
  `bottom_shape` enum('U-shaped','Rectangular','Modified Triangular','Flat') DEFAULT NULL,
  `link` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `FlowCytometry`
--

DROP TABLE IF EXISTS `FlowCytometry`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `FlowCytometry` (
  `origin` varchar(20) NOT NULL,
  `cloneID` int(11) NOT NULL,
  `M1` varchar(20) NOT NULL,
  `M2` varchar(20) NOT NULL,
  `M3` varchar(20) NOT NULL,
  `M4` varchar(20) NOT NULL,
  `profile` varchar(50) DEFAULT NULL,
  `pValue` float DEFAULT NULL,
  `effectSize` float DEFAULT NULL,
  `testType` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`cloneID`,`M1`,`M2`,`M3`,`M4`),
  KEY `fk_m4` (`M1`),
  KEY `FlowCytometry_ibfk_1` (`origin`,`cloneID`),
  CONSTRAINT `FlowCytometry_ibfk_1` FOREIGN KEY (`origin`, `cloneID`) REFERENCES `Perspective` (`origin`, `cloneID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_m1` FOREIGN KEY (`M1`) REFERENCES `CellSurfaceMarkers_hg19` (`hgnc_symbol`),
  CONSTRAINT `fk_m2` FOREIGN KEY (`M1`) REFERENCES `CellSurfaceMarkers_hg19` (`hgnc_symbol`),
  CONSTRAINT `fk_m3` FOREIGN KEY (`M1`) REFERENCES `CellSurfaceMarkers_hg19` (`hgnc_symbol`),
  CONSTRAINT `fk_m4` FOREIGN KEY (`M1`) REFERENCES `CellSurfaceMarkers_hg19` (`hgnc_symbol`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Identity`
--

DROP TABLE IF EXISTS `Identity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Identity` (
  `size` float NOT NULL,
  `whichPerspective` varchar(30) DEFAULT NULL,
  `rootID` int(11) DEFAULT NULL,
  `sampleSource` varchar(30) DEFAULT NULL,
  `cloneID` int(11) NOT NULL AUTO_INCREMENT,
  `profile` mediumblob,
  `profile_hash` int(11) DEFAULT NULL,
  `parent` int(11) DEFAULT NULL,
  `KaryotypePerspective` varchar(100) DEFAULT NULL,
  `GenomePerspective` varchar(100) DEFAULT NULL,
  `ExomePerspective` varchar(100) DEFAULT NULL,
  `TranscriptomePerspective` varchar(100) DEFAULT NULL,
  `coordinates` varchar(20) DEFAULT NULL,
  `profile_loci` int(11) DEFAULT NULL,
  `state` varchar(30) DEFAULT NULL,
  `alias` varchar(50) DEFAULT NULL,
  `hasChildren` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`cloneID`),
  KEY `profile_loci` (`profile_loci`),
  CONSTRAINT `identity_ibfk_1` FOREIGN KEY (`profile_loci`) REFERENCES `Loci` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2387 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `LiquidNitrogen`
--

DROP TABLE IF EXISTS `LiquidNitrogen`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `LiquidNitrogen` (
  `cellCount` bigint(20) NOT NULL,
  `id` varchar(20) DEFAULT NULL,
  `Rack` enum('1','2','3','4','5','6','7') NOT NULL,
  `Row` enum('1','2','3','4','5','6','7','8','9','10','11','12','13') NOT NULL COMMENT 'Top rack is row 1 and bottom rack is 13',
  `BoxRow` enum('A','B','C','D','E','F','G','H','I') NOT NULL,
  `BoxColumn` enum('1','2','3','4','5','6','7','8','9') NOT NULL,
  `Comment` varchar(40) DEFAULT NULL,
  PRIMARY KEY (`Rack`,`Row`,`BoxRow`,`BoxColumn`),
  KEY `FK_passagingID` (`id`),
  CONSTRAINT `FK_passagingID` FOREIGN KEY (`id`) REFERENCES `Passaging` (`id`),
  CONSTRAINT `LiquidNitrogen_ibfk_1` FOREIGN KEY (`id`) REFERENCES `Passaging` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Loci`
--

DROP TABLE IF EXISTS `Loci`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Loci` (
  `content` mediumblob,
  `hash` int(11) DEFAULT NULL,
  `id` int(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`),
  UNIQUE KEY `hash` (`hash`)
) ENGINE=InnoDB AUTO_INCREMENT=1313873 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Media`
--

DROP TABLE IF EXISTS `Media`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Media` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `base1` varchar(55) NOT NULL COMMENT 'Medium 1 used (EMEM, RPMI1640, EBSS, IMDM)',
  `base1_pct` float DEFAULT NULL COMMENT 'Medium 1 %',
  `base2` varchar(55) DEFAULT NULL COMMENT 'Medium 2 used (EMEM, RPMI1640,IMDM, EBSS)',
  `base2_pct` float DEFAULT '0' COMMENT 'Medium 2 %',
  `FBS` varchar(55) DEFAULT NULL COMMENT 'FBS (or FCS) is used as nutrition for the cells. Is a serum. Can be heat_inactivated or normal FBS',
  `FBS_pct` float DEFAULT '0' COMMENT 'FBS %',
  `EnergySource2` varchar(55) DEFAULT NULL,
  `EnergySource2_pct` double DEFAULT NULL,
  `EnergySource` varchar(55) DEFAULT NULL,
  `EnergySource_nM` float DEFAULT NULL,
  `HEPES` varchar(55) DEFAULT NULL COMMENT 'HEPES and other organic buffers can be used with many cell lines to effectively buffer the pH of the medium.? Indeed, some standard medium formulations include HEPES. However, this compound can be toxic, especially for some differentiated cell types, so evaluate its effects before use.? HEPES has been shown to greatly increase the sensitivity of media to the phototoxic effects induced by exposure to fluorescent light',
  `HEPES_mM` float DEFAULT '0' COMMENT 'List how much HEPES you are adding',
  `Salt` varchar(55) DEFAULT NULL,
  `Salt_nM` float DEFAULT NULL,
  `antibiotic` varchar(55) DEFAULT NULL COMMENT 'Can be Streptomycin or Penicellin',
  `antibiotic_pct` float DEFAULT '0' COMMENT 'Antibiotic 1 %',
  `growthFactors` varchar(55) DEFAULT NULL COMMENT 'Name if there are GF in the medium',
  `antibiotic2` varchar(55) DEFAULT NULL COMMENT 'Can be streptomycin or penicellin',
  `antibiotic2_pct` float DEFAULT '0' COMMENT 'Antibiotic 2 %',
  `antimycotic` varchar(55) DEFAULT NULL,
  `antimycotic_pct` float DEFAULT '0',
  `Stressor` varchar(55) DEFAULT NULL,
  `Stressor_concentration` float DEFAULT NULL,
  `Stressor_unit` enum('%','pMol','nMol','uMol','mMol','cMol','Mol') DEFAULT NULL,
  `comment` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `base1` (`base1`,`base1_pct`,`base2`,`base2_pct`,`FBS`,`FBS_pct`,`EnergySource2`,`EnergySource2_pct`,`EnergySource`,`EnergySource_nM`,`HEPES`,`HEPES_mM`,`antibiotic`,`antibiotic2`,`Stressor`,`Stressor_concentration`),
  KEY `base2` (`base2`),
  KEY `FBS` (`FBS`),
  KEY `non_essentia_amino_acid` (`EnergySource2`),
  KEY `HEPES` (`HEPES`),
  KEY `NaHCO3` (`Salt`),
  KEY `antibiotic` (`antibiotic`),
  KEY `antibiotic2` (`antibiotic2`),
  KEY `antimycotic` (`antimycotic`),
  KEY `EnergySource` (`EnergySource`),
  KEY `Drug` (`Stressor`),
  CONSTRAINT `Media_ibfk_1` FOREIGN KEY (`base1`) REFERENCES `MediaIngredients` (`name`),
  CONSTRAINT `Media_ibfk_10` FOREIGN KEY (`antimycotic`) REFERENCES `MediaIngredients` (`name`),
  CONSTRAINT `Media_ibfk_11` FOREIGN KEY (`EnergySource`) REFERENCES `MediaIngredients` (`name`),
  CONSTRAINT `Media_ibfk_12` FOREIGN KEY (`Stressor`) REFERENCES `MediaIngredients` (`name`),
  CONSTRAINT `Media_ibfk_2` FOREIGN KEY (`base2`) REFERENCES `MediaIngredients` (`name`),
  CONSTRAINT `Media_ibfk_3` FOREIGN KEY (`FBS`) REFERENCES `MediaIngredients` (`name`),
  CONSTRAINT `Media_ibfk_4` FOREIGN KEY (`EnergySource2`) REFERENCES `MediaIngredients` (`name`),
  CONSTRAINT `Media_ibfk_5` FOREIGN KEY (`EnergySource`) REFERENCES `MediaIngredients` (`name`),
  CONSTRAINT `Media_ibfk_6` FOREIGN KEY (`HEPES`) REFERENCES `MediaIngredients` (`name`),
  CONSTRAINT `Media_ibfk_7` FOREIGN KEY (`Salt`) REFERENCES `MediaIngredients` (`name`),
  CONSTRAINT `Media_ibfk_8` FOREIGN KEY (`antibiotic`) REFERENCES `MediaIngredients` (`name`),
  CONSTRAINT `Media_ibfk_9` FOREIGN KEY (`antibiotic2`) REFERENCES `MediaIngredients` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=53 DEFAULT CHARSET=latin1 COMMENT='HEPES and other organic buffers can be used with many cell l';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `MediaIngredients`
--

DROP TABLE IF EXISTS `MediaIngredients`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `MediaIngredients` (
  `name` varchar(55) NOT NULL,
  `vendor` varchar(255) DEFAULT NULL,
  `catalogue_number` varchar(40) DEFAULT NULL,
  `reference_number` varchar(40) DEFAULT NULL,
  `price` double DEFAULT NULL,
  `storage_degree_celsius` double DEFAULT NULL,
  `description` varchar(300) DEFAULT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Minus80Freezer`
--

DROP TABLE IF EXISTS `Minus80Freezer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Minus80Freezer` (
  `cellCount` bigint(20) NOT NULL,
  `id` varchar(20) DEFAULT NULL,
  `Drawer` enum('1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23','24','25','26','27','28','29','30','31','32','33','34','35','36','37','38','39','40') NOT NULL,
  `Position` enum('1','2','3','4','5') NOT NULL COMMENT 'Position 1 to 5. 1 front and 5 back',
  `BoxRow` enum('A','B','C','D','E','F','G','H','I') NOT NULL,
  `BoxColumn` enum('1','2','3','4','5','6','7','8','9') NOT NULL,
  `Comment` varchar(60) DEFAULT NULL,
  PRIMARY KEY (`Drawer`,`Position`,`BoxRow`,`BoxColumn`),
  KEY `id` (`id`),
  CONSTRAINT `Minus80Freezer_ibfk_1` FOREIGN KEY (`id`) REFERENCES `Passaging` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Passaging`
--

DROP TABLE IF EXISTS `Passaging`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Passaging` (
  `id` varchar(20) NOT NULL,
  `cellLine` varchar(20) DEFAULT NULL,
  `event` enum('seeding','harvest') NOT NULL,
  `passaged_from_id1` varchar(20) DEFAULT NULL,
  `passaged_from_id2` varchar(20) DEFAULT NULL,
  `growthType` varchar(30) DEFAULT NULL,
  `passage` int(11) NOT NULL,
  `cellCount` double DEFAULT NULL,
  `date` timestamp NOT NULL,
  `address` varchar(250) DEFAULT 'SRB Moffitt',
  `comment` varchar(100) DEFAULT NULL,
  `media` int(11) DEFAULT NULL,
  `dishSurfaceArea_cm2` float DEFAULT NULL,
  `feeding1` timestamp NULL DEFAULT NULL,
  `feeding2` timestamp NULL DEFAULT NULL,
  `feeding3` timestamp NULL DEFAULT NULL,
  `feeding4` timestamp NULL DEFAULT NULL,
  `Countess` double DEFAULT NULL,
  `feeding5` timestamp NULL DEFAULT NULL,
  `feeding6` timestamp NULL DEFAULT NULL,
  `feeding7` timestamp NULL DEFAULT NULL,
  `feeding8` timestamp NULL DEFAULT NULL,
  `feeding9` timestamp NULL DEFAULT NULL,
  `feeding10` timestamp NULL DEFAULT NULL,
  `backup_cellCount` double DEFAULT NULL,
  `feeding11` timestamp NULL DEFAULT NULL,
  `feeding12` timestamp NULL DEFAULT NULL,
  `feeding13` timestamp NULL DEFAULT NULL,
  `feeding14` timestamp NULL DEFAULT NULL,
  `feeding15` timestamp NULL DEFAULT NULL,
  `flask` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_harvest1` (`passaged_from_id1`),
  KEY `fk_harvest2` (`passaged_from_id2`),
  KEY `FK_cellLine` (`cellLine`),
  KEY `media` (`media`),
  KEY `FK_flaskID` (`flask`),
  CONSTRAINT `FK_cellLine` FOREIGN KEY (`cellLine`) REFERENCES `CellLinesAndPatients` (`name`),
  CONSTRAINT `FK_flaskID` FOREIGN KEY (`flask`) REFERENCES `Flask` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `Passaging_ibfk_1` FOREIGN KEY (`media`) REFERENCES `Media` (`id`),
  CONSTRAINT `Passaging_ibfk_2` FOREIGN KEY (`media`) REFERENCES `Media` (`id`),
  CONSTRAINT `fk_harvest1` FOREIGN KEY (`passaged_from_id1`) REFERENCES `Passaging` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_harvest2` FOREIGN KEY (`passaged_from_id2`) REFERENCES `Passaging` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`noemi`@`%`*/ /*!50003 TRIGGER passage_increment BEFORE INSERT ON Passaging
FOR EACH ROW BEGIN
  IF NEW.passage=0 THEN
    IF NEW.event='seeding' THEN
      SET NEW.passage = (SELECT passage +1 FROM Passaging WHERE id = NEW.passaged_from_id1);
    ELSE
      SET NEW.passage = (SELECT passage FROM Passaging WHERE id = NEW.passaged_from_id1);
    END IF;  
  END IF;
  IF NEW.cellLine IS NULL THEN
    SET NEW.cellLine = (SELECT cellLine FROM Passaging WHERE id = NEW.passaged_from_id1);
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `Perspective`
--

DROP TABLE IF EXISTS `Perspective`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Perspective` (
  `whichPerspective` varchar(30) DEFAULT NULL,
  `size` float DEFAULT NULL,
  `parent` int(11) DEFAULT NULL,
  `profile` mediumblob,
  `profile_hash` int(11) DEFAULT NULL,
  `origin` varchar(20) NOT NULL,
  `sampleSource` varchar(20) DEFAULT NULL,
  `coordinates` varchar(20) DEFAULT NULL,
  `rootID` int(11) DEFAULT NULL,
  `cloneID` int(11) NOT NULL AUTO_INCREMENT,
  `profile_loci` int(11) DEFAULT NULL,
  `state` varchar(30) DEFAULT NULL,
  `alias` varchar(50) DEFAULT NULL,
  `hasChildren` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`cloneID`),
  KEY `profile_loci` (`profile_loci`),
  KEY `FK_rootID` (`origin`),
  CONSTRAINT `FK_rootID` FOREIGN KEY (`origin`) REFERENCES `Passaging` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `perspective_ibfk_1` FOREIGN KEY (`profile_loci`) REFERENCES `Loci` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=134087 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2021-05-19  7:08:39
