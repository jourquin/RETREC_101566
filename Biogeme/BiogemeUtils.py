#!/usr/bin/python3

#
# Copyright (c) 1991-2021 Université catholique de Louvain
#
# <p>Center for Operations Research and Econometrics (CORE)
#
# <p>http://www.uclouvain.be
#
# <p>This file is part of Nodus.
#
# <p>Nodus is free software: you can redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# <p>This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# <p>You should have received a copy of the GNU General Public License along with this program. If
# not, see http://www.gnu.org/licenses/.
#

import os

# Delete existent model output
def dropExistentOutput(modelName):
    # Delete .html file 
    fileName = modelName + ".html"
    if os.path.isfile(fileName):
        os.remove(fileName)
        
        
    # Delete .pickle file 
    fileName = modelName + ".pickle"
    if os.path.isfile(fileName):
        os.remove(fileName)
        
    # Delete .log file 
    fileName = modelName + ".log"
    if os.path.isfile(fileName):
        os.remove(fileName)
        
    # Delete .iter file 
    fileName = "__" + modelName + ".iter"
    if os.path.isfile(fileName):
        os.remove(fileName)
        