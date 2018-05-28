class Cell {
  Organism organism;
  float x;
  float y;
  int id;

  float dx = 0;
  float dy = 0;
  float r = CELL_R;
 
  // Map of what cells are connected to this one 
  HashSet<Cell> connections = new HashSet<Cell>();
  
  // What proportion of division the cell has undertaken
  float divisionAmount = 0;
  Cell daughter;
  
  // What proportion of the cell is in light or in the soil
  float soilSurface = 0;
  float light = 0;
  
  // Metabolites
  float energy = 0;
  float nitrates = 0;
  float protein = 0;
  
  // Changes in metabolites
  float dEnergy = 0;
  float dNitrates = 0;
  float dProtein = 0;
  
  ArrayList<Enzyme> enzymes = new ArrayList<Enzyme>();
  Enzyme[] sensors = new Enzyme[3];

  Cell(Organism organism, float x, float y, int id) {
    this.organism = organism;
    this.x = x;
    this.y = y;
    this.id = id;
    
    // Add proteins
    sensors[0] = new LightSensor(this);
    sensors[1] = new EnergySensor(this);
    sensors[2] = new NitrateSensor(this);
      
    enzymes.add(new LightSensor(this));
    enzymes.add(new Chlorophyll(this));
    enzymes.add(new NitrateUptaker(this));
    enzymes.add(new Anabolism(this));
    enzymes.add(new EnergyPore(this));
    enzymes.add(new NitratePore(this));
    
    enzymes.get(1).addDomain(0, 100);
  }

  void draw() {
    strokeWeight(2);
    stroke(100, 200 * light, 200 * soilSurface);
    fill(100, 200 * light, 200 * soilSurface, 240);
    ellipse(x, y, r * 2, r * 2);
    
    textSize(10);
    textAlign(CENTER, CENTER);
    fill(255);
    //text(id, x, y);
    //text(soilSurface, x, y);
    //text(round(energy), x, y - 10);
    //text(round(nitrates), x, y);
    //text(round(protein), x, y + 10);
    
    textSize(12);
    //text(round(protein), x, y);
    //text(enzymes.get(0).activation, x, y - 10); //<>//
    text(enzymes.get(1).activation, x, y);
  }

  // Calculate the proportion of the cell's surface in contact with the soil
  void determineSoilCoverage() {
    float distanceBelowSoilTop = y - SOIL;
    
    if (distanceBelowSoilTop < -r) {
      soilSurface = 0;
    } else if (distanceBelowSoilTop > r) {
      soilSurface = 1;
    } else {
       soilSurface = (PI - 2 * asin(distanceBelowSoilTop / -r)) / TWO_PI;
    }
  }

  void metabolise() {
    // Determine activity of each protein
    for (Enzyme enzyme : enzymes) {
        enzyme.regulate();
    }
    
    // Update activity of each protein and find sum
    float totalActiveEnzymes = 0;
    for (Enzyme enzyme : enzymes) {
        enzyme.activation += enzyme.activationChange;
        totalActiveEnzymes += enzyme.activation;
    }
    
    // 10% of cell energy is available to meet protein upkeep costs
    if (totalActiveEnzymes * ENZYME_COST > energy * 0.1) {
        // Proteins deactivated as upkeeping costs aren't met
        float degradation = (energy * 0.1) / (totalActiveEnzymes * ENZYME_COST);
        for (Enzyme enzyme : enzymes) {
            enzyme.activation *= degradation;
        }
    }
    
    // Enzyme catalyse their reactions
    for (Enzyme enzyme : enzymes) {
      enzyme.update();
    }
  }
  
  void updateMetabolites() {
    energy += dEnergy;
    nitrates += dNitrates;
    protein += dProtein;
    dEnergy = 0;
    dNitrates = 0;
    dProtein = 0;
  }

  void move() {
    float damping = AIR_DAMPING * (1 - soilSurface) + SOIL_DAMPING * soilSurface;
    dx *= damping;
    dy *= damping;

    this.dy += GRAVITY;

    // Update positions
    x += dx + random(-0.1, 0.1);
    y += dy + random(-0.1, 0.1);

    // Hit the ground
    if (GRAVITY != 0 && y > GROUND - r) {
      y = GROUND - r;
    }
  }
  
  void startDivision() {
    protein -= REPLICATION_COST;
    divisionAmount = DIVISION_STEP; //<>//

    // Cytokinesis direction
    float ckx = random(-0.5, 0.5);
    float cky = random(-0.5, 0.5);
    
    // Normalise
    float d = sqrt(ckx * ckx + cky * cky);
    ckx /= d; 
    cky /= d;
    
    // Create a daughter cell
    daughter = organism.addDaughterCell(x + ckx, y + cky);
    
    // Connect mother and daughter
    this.connections.add(daughter);
    daughter.connections.add(this);
  }

  void divide() {
    // Proportion of division that has happened
    divisionAmount += DIVISION_STEP;
    
    // Move cells apart
    float targetDist = divisionAmount * (r + daughter.r);
    float dx = x - daughter.x;
    float dy = y - daughter.y;
    float currentDist = sqrt(dx * dx + dy * dy);
    float d = (targetDist - currentDist) * DIVISION_FORCE / currentDist;
    dx *= d;
    dy *= d;

    // Move cells apart
    this.dx += dx;
    this.dy += dy;
    daughter.dx -= dx;
    daughter.dy -= dy; //<>//
    
    // Ensure mother and daughter share resources until they split
    float halfEnergy = (energy + daughter.energy) * 0.5;
    float halfNitrates = (nitrates + daughter.nitrates) * 0.5;
    energy = halfEnergy;
    nitrates = halfNitrates;
    daughter.energy = halfEnergy;
    daughter.nitrates = halfNitrates;
    
    if (divisionAmount >= 1) {
        endDivision();
    }
  }
  
  void endDivision() {
    divisionAmount = 0;
    daughter = null;
  }
  
  boolean mouseOver() {
    return (dist(x, y, mouseX, mouseY) <= r);
  }
}
