//
//  YearsConstants.swift
//  BDE-ESEO
//
//  Created by Romain Rabouan on 16/09/2019.
//  Copyright © 2019 Romain Rabouan

//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.

//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.

//  You should have received a copy of the GNU General Public License
//  along with this program. If not, see http://www.gnu.org/licenses/
//

import UIKit

struct YearRank {
    let name: String
    let years: [String]
    let urls: [String]
}

let grades = [
    // Prépa intégrée
    [YearRank(name: "P1", years: ["2016-2017", "2017-2018"], urls:
        ["https://firebasestorage.googleapis.com/v0/b/eseokami.appspot.com/o/Annales%20d'examens%20appli%20BDE%2FDS%20P1%202016%202017.pdf?alt=media&token=2bf76199-5d98-4805-9a16-d6f119bbbe58",
         "https://firebasestorage.googleapis.com/v0/b/eseokami.appspot.com/o/Annales%20d'examens%20appli%20BDE%2FDS%20P1.pdf?alt=media&token=2d42724c-fbe6-49d1-a87c-08d6a184d7a9"]),
     YearRank(name: "P2", years: ["2016-2017", "2017-2018"], urls:
        ["https://firebasestorage.googleapis.com/v0/b/eseokami.appspot.com/o/Annales%20d'examens%20appli%20BDE%2FDS%20P2%202016%202017.pdf?alt=media&token=671b201c-c921-40de-ad86-4075f53d010c",
         "https://firebasestorage.googleapis.com/v0/b/eseokami.appspot.com/o/Annales%20d'examens%20appli%20BDE%2FDS%20P2.pdf?alt=media&token=49dde823-ffb4-4f8d-a5dd-d7517aae59bf"])],
    
    // Cycle ingénieur
    [YearRank(name: "I1/A1", years: ["2016-2017", "2017-2018"], urls:
        ["https://firebasestorage.googleapis.com/v0/b/eseokami.appspot.com/o/Annales%20d'examens%20appli%20BDE%2FDS%20I1%202016%202017.pdf?alt=media&token=03de67db-6ab5-429b-9511-30387ad69f72",
         "https://firebasestorage.googleapis.com/v0/b/eseokami.appspot.com/o/Annales%20d'examens%20appli%20BDE%2FDS%20I1.pdf?alt=media&token=1861de08-cbf2-4298-9ba9-91cf8a1301e6"]),
     YearRank(name: "I2/A2", years: ["2016-2017", "2017-2018"], urls:
        ["https://firebasestorage.googleapis.com/v0/b/eseokami.appspot.com/o/Annales%20d'examens%20appli%20BDE%2FDS%20I2%202016%202017.pdf?alt=media&token=096bfe0a-0d7e-4b46-9349-dadea5bba15e",
         "https://firebasestorage.googleapis.com/v0/b/eseokami.appspot.com/o/Annales%20d'examens%20appli%20BDE%2FDS%20I2.pdf?alt=media&token=e2cc1172-797d-4c51-8e9d-f3543c9c1f76"]),
     YearRank(name: "I3/A3", years: ["2016-2017", "2017-2018"], urls:
        ["https://firebasestorage.googleapis.com/v0/b/eseokami.appspot.com/o/Annales%20d'examens%20appli%20BDE%2FDS%20I3%202016%202017.pdf?alt=media&token=87dde144-6c3c-4ad4-9de3-4529ef015ce4",
         "https://firebasestorage.googleapis.com/v0/b/eseokami.appspot.com/o/Annales%20d'examens%20appli%20BDE%2FDS%20I3.pdf?alt=media&token=0518664d-a353-497a-b4a2-7dcbfe652ab2"])],
    
    // Bachelor
    [YearRank(name: "B1", years: ["2017-2018"], urls:
        ["https://firebasestorage.googleapis.com/v0/b/eseokami.appspot.com/o/Annales%20d'examens%20appli%20BDE%2FDS%20B1.pdf?alt=media&token=5e8b22c3-8bc6-4cff-9241-d0c5595f08ca"]),
     YearRank(name: "B2", years: ["2017-2018"], urls:
        ["https://firebasestorage.googleapis.com/v0/b/eseokami.appspot.com/o/Annales%20d'examens%20appli%20BDE%2FDS%20B2.pdf?alt=media&token=369476c8-0dd4-4981-b774-bb253fcf9710"])]
]

