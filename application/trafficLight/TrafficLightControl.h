/****************************************************************************/
/// @file    TrafficLightControl.h
/// @author  Philip Vo <foxvo@ucdavis.edu>
/// @author  Mani Amoozadeh <maniam@ucdavis.edu>
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

#ifndef TRAFFICLIGHTCONTROL_H
#define TRAFFICLIGHTCONTROL_H

#include <TrafficLightBase.h>
#include <Appl.h>
#include "TraCI_Extend.h"

using namespace std;

namespace VENTOS {

class TrafficLightControl : public TrafficLightBase
{
  public:
      virtual ~TrafficLightControl();
      virtual void finish();
      virtual void initialize(int);
      virtual void handleMessage(cMessage *);

  private:
      void executeFirstTimeStep();
      void executeEachTimeStep();

  public:

  private:
      int TLControlMode;
      double updateInterval;

      list<string> TLlidLst;
      list<string> VehicleLst;
      double nextTime;
      double passTime = 5;
      string prevEdge = "WC";
};

}

#endif
