pragma solidity >=0.4.21 <0.6.0;
/*  CARBONTRAIL - MODULE OPESTA
    Copyright (C) MXIX VALTHEFOX FOR MGNS. CAPITAL

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    See https://www.gnu.org/licenses/ for full terms.*/

//------VARIABLES---------

//reference_interne (String ASCII convertie en Hex) = R&#233;f&#233;rence dossier
//fiche (String ASCII convertie en Hex) = R&#233;f&#233;rence fiche_op&#233;ration_standardis&#233;e
//volumekWh(Integer) = Volume de CEE  en kWh CUMAC
//date_engagement(Integer) = Nombre de secondes entre le 1er Janvier 1970 et la date d&#39;engagement de l&#39;op&#233;ration
//date_facture(Integer) = Nombre de secondes entre le 1er Janvier 1970 et la date de facture
//pro = (String ASCII convertie en Hex) =  Identit&#233; du pro au format PNCEE (RAISON SOCIALE;SIREN;ou RAISON SOCIALE;SIREN SOUS TRAITANT;RAISON SOCIALE;SIREN SOUS TRAITANT) encod&#233;e avec l&#39;alogorithme MD5
//client_full (String ASCII convertie en Hex) =  Identit&#233; du client au format PNCEE (NOM;PRENOM pour un particulier RAISON SOCIALE;SIREN pour un professionnel) encod&#233;e avec l&#39;alogorithme MD5
//address_full (String ASCII convertie en Hex) = Adresse de r&#233;alisation de l&#39;op&#233;ration au format PNCEE (NUMERO DE VOIE NOM DE VOIE;CODE POSTAL; VILLE) encod&#233;e avec l&#39;alogorithme MD5
//declared_for (String ASCII convertie en Hex) = Adresse de l&#39;oblig&#233; dans la blockchain (e.g. MGNS. primary address = 0x62073c7c87c988f2Be0EAF41b5c0481df98e886E)

//nature_bon = Code parmi la liste suivante
//BACCARA : Arbitrage
//1 : Contribution financi&#232;re (monnaie fiducaire ou cryptomonnaie) 
//2 : Bon d&#39;achat pour des produits de consommation courante
//3 : Pr&#234;t bonifi&#233;
//4 : Audit ou conseil
//5 : Produit ou service offert
//6 : Op&#233;ration r&#233;alis&#233;e sur patrimoine propre


//status = Code parmi la liste suivante
//BACCARA : Test
//1: Annulation Non Conformit&#233;
//2: Annulation Droit Suppression GPDR Client 
//3: Annulation Erreur Saisie
//4: -
//5: Documents re&#231;us 
//6: Valid&#233; interne
//7: D&#233;pos&#233; PNCEE
//8: Arbitrage
//9: Valid&#233; PNCEE

//Exemple MGNS. s&#39;engage le 16/01/2019 a poser gratuitement des mousseurs sur les 750 robinets de l&#39;ECOLE DE CIRQUE PITRERIES 2 RUE DE STRASBOURG 83210 SOLLIES PONT SIRET 42493526000036. Pos&#233; et factur&#233; par FRANCE MERGUEZ DISTRIBUTION SIRET 34493368400021 le 17/01/2019. ASH num&#233;ro MPE400099. Enregistrement dans la blockchain lors du d&#233;pot au PNCEE.
//client_full : MD5 (&quot;ECOLE DE CIRQUE PITRERIES;42493526&quot;) = 95be74bce973b492a060a4a5e38fb916 -> 0x95be74bce973b492a060a4a5e38fb916
//adress_full : MD5 (&quot;2 RUE DE STRASBOURG;83210;SOLLIES PONT&quot;) = c86f2d95804c4af2a1cbf85d64df29e0 -> 0xc86f2d95804c4af2a1cbf85d64df29e0
//pro : MD5 (&quot;FRANCE MERGUEZ DISTRIBUTION;344933684&quot;) = 4cf60fe171f7487aedb1c0892f2614eb -> 0x4cf60fe171f7487aedb1c0892f2614eb
//declared_for :  0x62073c7c87c988f2Be0EAF41b5c0481df98e886E
//nature_bon : 5
//status : 7
//reference_interne : MPE400099 -> 0x4D50453430303039390A
//fiche : BAT-EQ-133 -> 0x4241542D45512D3133330A
//volumekWh : 2031750
//date_engagement : 1547659037
//date_facture : 1547745437

contract CARBONTRAIL_OPESTA {
    event OPESTA(
        bytes32 client_full, 
        bytes32 address_full,
        bytes32 pro,
        address declared_by,
        address declared_for,
        uint nature_bon,
        uint status,
        bytes32 reference_interne,
        bytes32 fiche,
        uint volumekWh,
        uint date_engagement,
        uint date_facture,
        uint timestamp,
        uint block
    );

    function newOPESTA(bytes32 client_full, bytes32 address_full, bytes32 pro, address declared_for, uint nature_bon, uint status, bytes32 reference_interne, bytes32 fiche, uint volumekWh, uint date_engagement, uint date_facture) public  {
        emit OPESTA(client_full, address_full, pro, msg.sender, declared_for, nature_bon, status, reference_interne, fiche, volumekWh, date_engagement, date_facture, block.timestamp, block.number);
    }
    
    event UOPESTA(
        bytes32 client_full, 
        bytes32 address_full,
        bytes32 pro,
        address declared_by,
        address declared_for,
        uint nature_bon,
        uint status,
        bytes32 reference_interne,
        bytes32 fiche,
        uint volumekWh,
        uint date_engagement,
        uint date_facture,
        uint timestamp,
        uint block
    );

    function updateOPESTA(bytes32 client_full, bytes32 address_full, bytes32 pro, address declared_for, uint nature_bon, uint status, bytes32 reference_interne, bytes32 fiche, uint volumekWh, uint date_engagement, uint date_facture) public  {
        emit UOPESTA(client_full, address_full, pro, msg.sender, declared_for, nature_bon, status, reference_interne, fiche, volumekWh, date_engagement, date_facture, block.timestamp, block.number);
    }
}