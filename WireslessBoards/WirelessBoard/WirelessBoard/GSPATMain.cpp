#include <AsierInhoUDP.h>
#include <GSPAT_SolverV2.h>
#include <Helper\HelperMethods.h>
#include <Helper\microTimer.h>
#include <string.h>
#include <conio.h>

void print(const char* str) {
	printf("%s\n", str);
}

void updatePhasesAndAmplitudes(AsierInhoUDP::AsierInhoUDPBoard* driver, float* phases, float* amplitudes) {
	unsigned char* message = driver->discretize(phases, amplitudes);
	driver->updateMessage(message);
}

void main(void) {
	//Create driver and connect to it
	AsierInhoUDP::RegisterPrintFuncs(print, print, print);
	AsierInhoUDP::AsierInhoUDPBoard* driver = AsierInhoUDP::createAsierInho();
	//Setting the board
	int numBoards = 1;
	float height = 0.12f;
	///int numTransducers = 64 * numBoards;
	int boardIDs[] = { 7, 2 };
	float matBoardToWorld[32] = { // only using the top board in this example
		/*bottom*/
		1, 0, 0, 0,
		0, 1, 0, 0,
		0, 0, 1, 0,
		0, 0, 0, 1,
		/*top*/
		-1, 0, 0, 0,
		0, 1, 0, 0,
		0, 0,-1, height,
		0, 0, 0, 1,
	};
	//Create solver:
	GSPAT_V2::RegisterPrintFuncs(print, print, print);
	GSPAT::Solver* solver = GSPAT_V2::createSolver(128);//Number of transducers used (two boards of 16x16)
	if (!driver->connect(numBoards, boardIDs, matBoardToWorld))	//Device IDs to connect to
		printf("Failed to connect to board.");

	float transducerPositions[128 * 3], transducerNormals[128 * 3], amplitudeAdjust[128];
	int mappings[128], phaseDelays[128], numDiscreteLevels;
	driver->readParameters(transducerPositions, transducerNormals, mappings, phaseDelays, amplitudeAdjust, &numDiscreteLevels);
	solver->setBoardConfig(transducerPositions, transducerNormals, mappings, phaseDelays, amplitudeAdjust, numDiscreteLevels);
	
	//Program: Create a trap and move it with the keyboard
	const size_t numPoints = 2; //Change this if you want (but make sure to change also each point's position )
	const size_t numGeometries = 1;//Please, do not change this. Multiple update Messages require AsierInhoV2 (see 6.simpleGSPATCpp_AsierInhoV2)
	static float radius = 0.00865f * 1.5f;// 0.02f;
	float curPos[4 * numGeometries * numPoints];
	float amplitude[numGeometries * numPoints];
	for (int g = 0; g < numGeometries; g++) {
		for (int p = 0; p < numPoints; p++) {
			float angle = 2 * M_PI / numPoints;
			curPos[4 * g * numPoints + 4 * p + 0] = radius * cos(p * angle);
			curPos[4 * g * numPoints + 4 * p + 1] = radius * sin(p * angle);
			curPos[4 * g * numPoints + 4 * p + 2] = height/2.f;
			curPos[4 * g * numPoints + 4 * p + 3] = 1;
			amplitude[g * numPoints + p] = 40000;
		}
	}
	unsigned char* msg;
	float mI[] = { 1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1 };
	float matrix[16 * numPoints];
	for (int i = 0; i < numPoints; i++)
		memcpy(&matrix[16 * i], mI, 16 * sizeof(float));
	//a. create a solution
	GSPAT::Solution* solution = solver->createSolution(numPoints, numGeometries, true, curPos, amplitude, matrix, matrix);
	solver->compute(solution);
	solution->finalMessages(&msg);
	for (int s = 0; s < 16; s++)//Fill FPGA buffers so update is processed directly
		driver->updateMessage(msg);
	solver->releaseSolution(solution);

	//b. Main loop (finished when space bar is pressed):
	printf("\n Place a bead at (%f,%f,%f)\n ", curPos[0], curPos[1], curPos[2]);
	printf("Use keys A-D , W-S and Q-E to move the bead\n");
	printf("Press 'X' to destroy the solver.\n");

	bool finished = false;
	while (!finished) {
		//Update 3D position from keyboard presses
		switch (_getch()) {
		case 'a':
			for (int g = 0; g < numGeometries; g++)
				for (int p = 0; p < numPoints; p++)
					curPos[4 * g * numPoints + 4 * p + 0] += 0.0005f; break;
		case 'd':
			for (int g = 0; g < numGeometries; g++)
				for (int p = 0; p < numPoints; p++)
					curPos[4 * g * numPoints + 4 * p + 0] -= 0.0005f; break;
		case 'w':
			for (int g = 0; g < numGeometries; g++)
				for (int p = 0; p < numPoints; p++)
					curPos[4 * g * numPoints + 4 * p + 1] += 0.0005f; break;
		case 's':
			for (int g = 0; g < numGeometries; g++)
				for (int p = 0; p < numPoints; p++)
					curPos[4 * g * numPoints + 4 * p + 1] -= 0.0005f; break;
		case 'q':
			for (int g = 0; g < numGeometries; g++)
				for (int p = 0; p < numPoints; p++)
					curPos[4 * g * numPoints + 4 * p + 2] += 0.00025f; break;
		case 'e':
			for (int g = 0; g < numGeometries; g++)
				for (int p = 0; p < numPoints; p++)
					curPos[4 * g * numPoints + 4 * p + 2] -= 0.00025f; break;
		case 'x':
		case 'X':
			finished = true;

		}
		//Create the trap and send to the board:
		GSPAT::Solution* solution = solver->createSolution(numPoints, numGeometries, true, curPos, amplitude, matrix, matrix);
		solver->compute(solution);
		solution->finalMessages(&msg);
		for (int s = 0; s < 16; s++)//Fill FPGA buffers so update is processed directly
			driver->updateMessage(msg);
		solver->releaseSolution(solution);
		printf("\n Bead location (%f,%f,%f)\n ", curPos[0], curPos[1], curPos[2]);
	}
	//Deallocate the AsierInho controller: 
	driver->turnTransducersOff();
	Sleep(100);
	driver->disconnect();
	delete driver;
	delete solver;
}
