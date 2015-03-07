/****************************************************************************/
/// @file    ApplRSU_02_AID.cc
/// @author  Mani Amoozadeh <maniam@ucdavis.edu>
/// @author  second author name
/// @date    August 2013
///
/****************************************************************************/
// VENTOS, Vehicular Network Open Simulator; see http:?
// Copyright (C) 2013-2015
/****************************************************************************/
//
// This file is part of VENTOS.
// VENTOS is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//

#include "ApplRSU_02_AID.h"

namespace VENTOS {

MatrixXi ApplRSUAID::tableCount;
MatrixXd ApplRSUAID::tableProb;

Define_Module(VENTOS::ApplRSUAID);

ApplRSUAID::~ApplRSUAID()
{

}


void ApplRSUAID::initialize(int stage)
{
	ApplRSUBase::initialize(stage);

	if (stage==0)
	{
        // todo: change n and m dynamically!
        tableCount = MatrixXi::Zero(3, 2000);
        tableProb = MatrixXd::Constant(3, 2000, 0.1);

        printIncidentDetection = par("printIncidentDetection").boolValue();

        Signal_executeEachTS = registerSignal("executeEachTS");

        // only one RSU is registered with this signal
        if(printIncidentDetection && string("RSU[0]") == myFullId)
            simulation.getSystemModule()->subscribe("executeEachTS", this);
	}
}


void ApplRSUAID::finish()
{
    ApplRSUBase::finish();
}


void ApplRSUAID::handleSelfMsg(cMessage* msg)
{
    ApplRSUBase::handleSelfMsg(msg);
}


// only RSU[0] executes this
void ApplRSUAID::receiveSignal(cComponent *source, simsignal_t signalID, long i)
{
    Enter_Method_Silent();

    if(signalID == Signal_executeEachTS)
        incidentDetectionToFile();
}


void ApplRSUAID::incidentDetectionToFile()
{
    boost::filesystem::path filePath;

    if( ev.isGUI() )
    {
        filePath = "results/gui/IncidentTable.txt";
    }
    else
    {
        // get the current run number
        int currentRun = ev.getConfigEx()->getActiveRunNumber();
        ostringstream fileName;
        fileName << currentRun << "_IncidentTable.txt";
        filePath = "results/cmd/" + fileName.str();
    }

    ofstream filePtr( filePath.string().c_str() );

    if (filePtr.is_open())
    {
        filePtr << tableCount;
    }

    filePtr.close();
}


void ApplRSUAID::onBeaconVehicle(BeaconVehicle* wsm)
{
    // no passing down!
}


void ApplRSUAID::onBeaconBicycle(BeaconBicycle* wsm)
{
    // no passing down!
}


void ApplRSUAID::onBeaconPedestrian(BeaconPedestrian* wsm)
{
    // no passing down!
}


void ApplRSUAID::onBeaconRSU(BeaconRSU* wsm)
{
    // no passing down!
}


void ApplRSUAID::onData(LaneChangeMsg* wsm)
{
    // no passing down!

    deque<string> input = wsm->getLaneChange();

    for(unsigned int i = 0; i < input.size(); i++)
    {
        // tokenize
        int readCount = 1;
        char_separator<char> sep("#", "", keep_empty_tokens);
        tokenizer< char_separator<char> > tokens(input[i], sep);

        string fromLane;
        string toLane;
        double fromX;
        double toX;
        double time;

        for(tokenizer< char_separator<char> >::iterator beg=tokens.begin(); beg!=tokens.end();++beg)
        {
            if(readCount == 1)
            {
                fromLane = (*beg);
            }
            else if(readCount == 2)
            {
                toLane = (*beg);
            }
            else if(readCount == 3)
            {
                fromX = atof( (*beg).c_str() );
            }
            else if(readCount == 4)
            {
                toX = atof( (*beg).c_str() );
            }
            else if(readCount == 5)
            {
                time = atof( (*beg).c_str() );
            }

            readCount++;
        }

        // todo: change them dynamically
        int index_N_start = floor(fromX / 5);
        int index_N_end = floor(toX / 5);
        int index_M = -1;

        if(fromLane == "")
            fromLane = toLane;

        if(fromLane == "1to2_0")
        {
            index_M = 0;
        }
        else if(fromLane == "1to2_1")
        {
            index_M = 1;
        }
        else if(fromLane == "1to2_2")
        {
            index_M = 2;
        }

        // increase all corresponding indices in tableCount by 1
        for(int j = index_N_start; j <= index_N_end; j++)
        {
            tableCount(index_M, j) = tableCount(index_M, j) + 1;
        }
    }
}

}

