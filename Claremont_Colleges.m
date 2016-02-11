rng; % seed number generator
% time we let couples form until we introduce disease into 
timeUntilSimulation = 5;
% simulation time
trackingTime = 10;
simulationTime = 20-trackingTime;

Amen = zeros(1,trackingTime*365);
Smen = zeros(1,trackingTime*365);
Awomen = zeros(1,trackingTime*365);
Swomen = zeros(1,trackingTime*365);

population_size = 5800; % approximate size of Claremont colleges
half_population_size = population_size/2;
names = 1:population_size;
% sex ratio of 40% men, 60% women, purely heterosexual, females 0 males 1
men_population_size = 0.40*population_size;
female_population_size = population_size-men_population_size;
sex = [zeros(1,female_population_size) ones(1,men_population_size)];
% ages: uniformly random from 18 to 21
age = randi(4,1,population_size) + 17;
% default sexual activity to 0 but since college campus maybe higher
% sexual acitivity, so for each student probabilisitically set their 
% activity to high
sa = zeros(1,population_size);
allIndividuals = find(sa==0);
% 10% of population 
probability_high_sex_activity = 0.10;
for i=allIndividuals
    rr = rand;
    if rr <= probability_high_sex_activity
        sa(i) = 1;
    end
end
% Next we want them all to be susceptible
disease = zeros(1,population_size);
% Want all of their time since infection to be -1 (susceptible)
tau = zeros(1,population_size) - 1;
% Everyone stats single, so d=0
numPartners = zeros(1,population_size);
% The set of names of current partners will be kept in a MATLAB sparse
% matrix and therefore we initialize this to be:
relationshipMatrix = zeros(population_size,population_size);
%       A casual relationship will be denoted with a 1 whereas a serious
%       relationship will be denoted with a 2

%------------------------------------NEEDED RATES-------------------------%
% transmission rates
T_male2female_steady = 0.0385;
T_female2male_steady = 0.0305;
T_male2female_casual = 0.154;
T_female2male_casual = 0.122;
% percent asymptomatic
asymptomatic_males = 0.25;
asymptomatic_females = 0.70;
% incubation times
incubation_time_male = 12;
incubation_time_female = 10;
% patient delay and treatment times
delayANDtreatment_male = 11;
delayANDtreatment_female = 14;
% recovery rates
recovery_asymp_male = 0.005;
recovery_symp_male = 0.03;
recovery_asymp_female = 0.0027;
recovery_symp_female = 0.025;
%-------------------------------------------------------------------------%
 % ------ Partnership Loop!
for days = 1 : (timeUntilSimulation*365) % each time step 
    % 1) Form Partnerships
    % how to find the total number of partnerships 
    inRelationship = find(numPartners~=0);
    partnerships = 0;
    for person = inRelationship
        partnerships = (partnerships + numPartners(person));
    end
    partnerships = (partnerships/2);
    iterations = ( half_population_size - partnerships );
    
    for i=1:iterations
        X = rand; % form a partnership with p = 0.006
        if (X <= 0.006) % partnership will be formed!
            Y = rand; %i) steady with f=0.2 otherwise casual 
            if (Y <= 0.2) % steady relationship: denoted with a 2
                coupleFormed = 0;
                while (coupleFormed == 0)
                    Z = rand;
                    %ii) male y and female x drawn from population
                    female = randi(half_population_size,1);
                    male = randi([half_population_size+1,population_size],1);
                    % Our mixing probability function requires the terms:
                    % extract terms:
                    femaleAge = age(female);
                    femaleSA = sa(female);
                    femaleNumPartners = numPartners(female);
                    maleAge = age(male);
                    maleSA = sa(male);
                    maleNumPartners = numPartners(male);
                    
                    mixing_prob = 0;
                    %iii) form partnership with probability phi(x,y) AS
                    %LONG AS they are not already in a relationship
                    if (relationshipMatrix(female,male) == 0)
                        mixing_prob = mixing_probability_function(femaleAge,...
                            femaleSA,femaleNumPartners,maleAge,maleSA,...
                            maleNumPartners,2);
                    end
                    if (mixing_prob >= Z)
                        % MAKE COUPLE: INDICATE COUPLE (& STEADY) IN
                        % RELATIONSHIP MATRIX
                        relationshipMatrix(female,male) = 2;
                        relationshipMatrix(male,female) = 2;
                        numPartners(female) = (numPartners(female) + 1);
                        numPartners(male) = (numPartners(male) + 1);
                        coupleFormed = 1;
                    end
                    %iv) if x and y don't form partnership -> repeat ii) 
                    % and iii) until a partnership is formed
                end
            end
            if (Y > 0.2) % we know that a casual relationship is formed
                coupleFormed = 0;
                while (coupleFormed == 0)
                    Z = rand;
                    %ii) male y and female x drawn from population
                    female = randi(half_population_size,1);
                    male = randi([half_population_size+1,population_size],1);
                    % Our mixing probability function requires the terms:
                    % age, sexual activity, number of partners
                    % extract terms:
                    femaleAge = age(female);
                    femaleSA = sa(female);
                    femaleNumPartners = numPartners(female);
                    maleAge = age(male);
                    maleSA = sa(male);
                    maleNumPartners = numPartners(male);
                    
                    mixing_prob = 0;
                    %iii) form partnership with probability phi(x,y) AS
                    %LONG AS not in relationship already
                    if (relationshipMatrix(female,male) == 0)
                        mixing_prob = mixing_probability_function(femaleAge,...
                            femaleSA,femaleNumPartners,maleAge,maleSA,...
                            maleNumPartners,1);
                    end
                    
                    if (mixing_prob >= Z)
                        % MAKE COUPLE: INDICATE COUPLE (& CASUAL) IN
                        % RELATIONSHIP MATRIX
                        relationshipMatrix(female,male) = 1;
                        relationshipMatrix(male,female) = 1;
                        numPartners(female) = (numPartners(female) + 1);
                        numPartners(male) = (numPartners(male) + 1);
                        coupleFormed = 1;
                    end
                    %iv) if x and y don't form partnership -> repeat ii) 
                    % and iii) until a partnership is formed
                end
            end        
        end
    end
    % Separation of partnerships
    % with probability 0.0004 steady partnerships break
    % with probability 0.1 casual partnerships break
    
    for i = 1:half_population_size %rows: females!
        for j = half_population_size+1:population_size; %cols: males!
            if (relationshipMatrix(i,j) ~= 0) %in some sort of relationship
                rr = rand;
                if (relationshipMatrix(i,j) == 1) % in casual relationship
                     if (rr <= 0.1)
                         % i and j break up
                         % separation causes N -> N\{name of partner}
                         relationshipMatrix(i,j) = 0;
                         relationshipMatrix(j,i) = 0;
                         % number of relationships each partner has
                         % decreases by 1
                         % separation causes d -> d-1
                         numPartners(i) = (numPartners(i) - 1);
                         numPartners(j) = (numPartners(j) - 1);
                     end
                elseif (relationshipMatrix(i,j) == 2) % in steady relationship
                     if (rr <= 0.0004)
                         relationshipMatrix(i,j) = 0;
                         relationshipMatrix(j,i) = 0;

                         numPartners(i) = (numPartners(i) - 1);
                         numPartners(j) = (numPartners(j) - 1);
                     end
                end
            end
        end
    end
    

    % Replacement (NOTE WHEN I INCREMENT AGES)
    % all 22y.o. replaced with 18 year old of same name, gender, but for
    % this replacement a=18, c=c', s=0, tau=-1, d=0 and N= empty set
    % c' denotes new activity status
    graduates = find(age == 22);
    for i=graduates
        age(i) = 18;
        disease(i) = 0;
        tau(i) = -1;
        numPartners(i) = 0;
        sa(i) = 0;
        rr =  rand;
        if (rr <= 0.05)
            sa(i) = 1;
        end
        
        %NEED TO REMOVE RELATIONSHIPS INVOLVING THIS 65 YEAR OLD IN
        %RELATIONSHIP MATRIX AND NUM PARTNERS OF EVERYONE INVOLVED
        for partner=1:population_size
            % IF there is relationship between an individual and i
            % then we need to break that off 
            if (relationshipMatrix(partner,i) ~= 0)
                % relationship exists --> END IT
                relationshipMatrix(partner,i) = 0;
                relationshipMatrix(i,partner) = 0;

                numPartners(partner) = (numPartners(partner) - 1);
            end
        end 
    end
    
    % INCREMENT AGES WHEN APPROPRIATE
    for i = 1:timeUntilSimulation
        if (days == 365*i)
            % a year has passed and therefore we increment all ages
            age = (age + 1);
        end
    end
end

% Introduce Disease
% introduce disease into core group, that is, we wish to
% introduce disease into individuals with c=1
coreGroup = find(sa == 1 );
for j = coreGroup
    rr = rand;
    p = 0.50; % what % of core group gets Chlamydia
    if (rr <= p)
        if (sex(j) == 1) % male
            % we know % assymp men = 25
            maleRR = rand;
            if (maleRR <= asymptomatic_males)
                %assymptomatically infected
                disease(j) = 2;
                tau(j) = 0;
            else
                %symptomatically infected
                disease(j) = 1; 
                tau(j) = 0;
            end
        else % we know it is a female 
            % we know % assymp women = 70
            femaleRR = rand;
            if (femaleRR <= asymptomatic_females)
                %assymptomatically infected
                disease(j) = 2;
                tau(j) = 0;
            else
                %symptomatically infected
                disease(j) = 1; 
                tau(j) = 0;
            end
        end 
    end
end
        
     
    
    
    
for days = 1 : (simulationTime*365) % each time step
    
    % ------For all infected people, a day has gone by so their time since
    % infection, or tau, has increased by a day -------------------------%
    tau = tau + (tau >= 0);
    %---------------------------------------------------------------------%
    
    % 1) Form Partnerships
    % how to find the total number of partnerships 
    inRelationship = find(numPartners~=0);
    partnerships = 0;
    for person = inRelationship
        partnerships = (partnerships + numPartners(person));
    end
    partnerships = (partnerships/2);
    iterations = ( half_population_size - partnerships );
    
    for i=1:iterations
        X = rand; % form a partnership with p = 0.006
        if (X <= 0.006) % partnership will be formed!
            Y = rand; %i) steady with f=0.2 otherwise casual 
            if (Y <= 0.2) % steady relationship: denoted with a 2
                coupleFormed = 0;
                while (coupleFormed == 0)
                    Z = rand;
                    %ii) male y and female x drawn from population
                    female = randi(half_population_size,1);
                    male = randi([half_population_size+1,population_size],1);
                    % Our mixing probability function requires the terms:
                    % extract terms:
                    femaleAge = age(female);
                    femaleSA = sa(female);
                    femaleNumPartners = numPartners(female);
                    maleAge = age(male);
                    maleSA = sa(male);
                    maleNumPartners = numPartners(male);
                    
                    mixing_prob = 0;
                    %iii) form partnership with probability phi(x,y) AS
                    %LONG AS they are not already in a relationship
                    if (relationshipMatrix(female,male) == 0)
                        mixing_prob = mixing_probability_function(femaleAge,...
                            femaleSA,femaleNumPartners,maleAge,maleSA,...
                            maleNumPartners,2);
                    end
                    if (mixing_prob >= Z)
                        % MAKE COUPLE: INDICATE COUPLE (& STEADY) IN
                        % RELATIONSHIP MATRIX
                        relationshipMatrix(female,male) = 2;
                        relationshipMatrix(male,female) = 2;
                        numPartners(female) = (numPartners(female) + 1);
                        numPartners(male) = (numPartners(male) + 1);
                        coupleFormed = 1;
                    end
                    %iv) if x and y don't form partnership -> repeat ii) 
                    % and iii) until a partnership is formed
                end
            end
            if (Y > 0.2) % we know that a casual relationship is formed
                coupleFormed = 0;
                while (coupleFormed == 0)
                    Z = rand;
                    %ii) male y and female x drawn from population
                    female = randi(half_population_size,1);
                    male = randi([half_population_size+1,population_size],1);
                    % Our mixing probability function requires the terms:
                    % age, sexual activity, number of partners
                    % extract terms:
                    femaleAge = age(female);
                    femaleSA = sa(female);
                    femaleNumPartners = numPartners(female);
                    maleAge = age(male);
                    maleSA = sa(male);
                    maleNumPartners = numPartners(male);
                    
                    mixing_prob = 0;
                    %iii) form partnership with probability phi(x,y) AS
                    %LONG AS not in relationship already
                    if (relationshipMatrix(female,male) == 0)
                        mixing_prob = mixing_probability_function(femaleAge,...
                            femaleSA,femaleNumPartners,maleAge,maleSA,...
                            maleNumPartners,1);
                    end
                    
                    if (mixing_prob >= Z)
                        % MAKE COUPLE: INDICATE COUPLE (& CASUAL) IN
                        % RELATIONSHIP MATRIX
                        relationshipMatrix(female,male) = 1;
                        relationshipMatrix(male,female) = 1;
                        numPartners(female) = (numPartners(female) + 1);
                        numPartners(male) = (numPartners(male) + 1);
                        coupleFormed = 1;
                    end
                    %iv) if x and y don't form partnership -> repeat ii) 
                    % and iii) until a partnership is formed
                end
            end        
        end
    end
    
    % 2) Disease transmission
    % for every couple in which s=0 for one but s=1,2 and tau > incubation
    % for the other, disease- and gender-specific probability of disease
    % transmission NOTE: IN MATRICES: (row,column)
    
    for i = 1:half_population_size %rows: (all females)
        for j = half_population_size+1:population_size; %cols: (all males)
            if (relationshipMatrix(i,j) ~= 0) %in some sort of relationship
                dF = disease(i);
                dM = disease(j);
                rel = relationshipMatrix(i,j);
                tauF = tau(i);
                tauM = tau(j);
                
                diseaseNUM = DISEASE(dF,tauF,dM,tauM,incubation_time_female,...
                    incubation_time_male,rel,T_male2female_steady, ...
                    T_female2male_steady,T_male2female_casual,...
                    T_female2male_casual, asymptomatic_males, ...
                    asymptomatic_females );
                
                if (diseaseNUM ~= 0) % some change happens
                    if (diseaseNUM == 1)
                        disease(i) = 2;
                        tau(i) = 0;
                    elseif (diseaseNUM == 2)
                        disease(i) = 1;
                        tau(i) = 0;
                    elseif (diseaseNUM == 3)
                        disease(j) = 2;
                        tau(j) = 0;
                    elseif(diseaseNUM == 4)
                        disease(j) = 1;
                        tau(j) = 0;
                    end
                end
            end
        end
    end

    
    % 3) Separation of partnerships
    % with probability 0.0004 steady partnerships break
    % with probability 0.1 casual partnerships break
    
    for i = 1:half_population_size %rows: females!
        for j = half_population_size+1:population_size; %cols: males!
            if (relationshipMatrix(i,j) ~= 0) %in some sort of relationship
                rr = rand;
                if (relationshipMatrix(i,j) == 1) % in casual relationship
                     if (rr <= 0.1)
                         % i and j break up
                         % separation causes N -> N\{name of partner}
                         relationshipMatrix(i,j) = 0;
                         relationshipMatrix(j,i) = 0;
                         % number of relationships each partner has
                         % decreases by 1
                         % separation causes d -> d-1
                         numPartners(i) = (numPartners(i) - 1);
                         numPartners(j) = (numPartners(j) - 1);
                     end
                elseif (relationshipMatrix(i,j) == 2) % in steady relationship
                     if (rr <= 0.0004)
                         relationshipMatrix(i,j) = 0;
                         relationshipMatrix(j,i) = 0;

                         numPartners(i) = (numPartners(i) - 1);
                         numPartners(j) = (numPartners(j) - 1);
                     end
                end
            end
        end
    end
    
    % 4) Replacement (NOTE WHEN I INCREMENT AGES)
    % all 65y.o. replaced with 15 year old of same name, gender, but for
    % this replacement a=15, c=c', s=0, tau=-1, d=0 and N= empty set
    % c' denotes new activity status
    old = find(age == 65);
    for i=old
        age(i) = 15;
        disease(i) = 0;
        tau(i) = -1;
        numPartners(i) = 0;
        sa(i) = 0;
        rr =  rand;
        if (rr <= 0.05)
            sa(i) = 1;
        end
        
        %NEED TO REMOVE RELATIONSHIPS INVOLVING THIS 65 YEAR OLD IN
        %RELATIONSHIP MATRIX AND NUM PARTNERS OF EVERYONE INVOLVED
        for partner=1:population_size
            % IF there is relationship between an individual and i
            % then we need to break that off 
            if (relationshipMatrix(partner,i) ~= 0)
                % relationship exists --> END IT
                relationshipMatrix(partner,i) = 0;
                relationshipMatrix(i,partner) = 0;

                numPartners(partner) = (numPartners(partner) - 1);
            end
        end 
    end
    
    % 5) Recovery
    % transition from s=1 or s=2 to s=0 with disease- and gender-specific
    % probabilities
    
    sick = find(disease ~= 0 );
    for i = sick
        if (sex(i) == 0)
            % person is female
            rr =rand;
            if ((disease(i) == 1) && (rr <= recovery_symp_female))
                % symptomatically infected & recovers
                disease(i) = 0;
                tau(i) = -1;
            elseif ( (disease(i) == 2) && (rr <= recovery_asymp_female))
                % assymptomatically infected & recovers
                disease(i) = 0;
                tau(i) = -1;
            end
        elseif (sex(i) == 1)
            % person is male
            rr =rand;
            if ((disease(i) == 1) && (rr <= recovery_symp_male))
                % symptomatically infected & recovers
                disease(i) = 0;
                tau(i) = -1;
            elseif ((disease(i) == 2) && (rr <= recovery_asymp_male))
                % assymptomatically infected & recovers
                disease(i) = 0;
                tau(i) = -1;
            end
        end 
    end
    
    % 6) Treatment (and contact tracing). Transition of symptomatically
    % infecteds (s=1) with tau = incubation time and patient delay to s=0
    % with probability 1 (treatment is 100% effective). Contact tracing: at
    % treatment of symptomatically infected, all partners in N also return
    % disease status s=0. 
%     symptomaticallySick = find(population.disease == 1 );
%     maleTime = delayANDtreatment_male + incubation_time_male;
%     femaleTime = delayANDtreatment_female + incubation_time_female;
%     for i = symptomaticallySick
%         if ( (population.sex(i) == 0) && (population.tau(i) >= femaleTime))
%             % female and partners get treated
%             population.disease(i) = 0;
%             population.tau(i) = -1;
% %             for j = 1:population_size
% %                 if (relationshipMatrix(symptomaticallySick,j) ~= 0)
% %                     population.disease(j) = 0;
% %                     population.tau(j) = -1;
% %                 end
% %             end    
%         elseif ( (population.sex(i) == 1) && (population.tau(i) >= maleTime))
%             % male and partners get treated
%             population.disease(i) = 0;
%             population.tau(i) = -1;
% %             for j = 1:population_size
% %                 if (relationshipMatrix(symptomaticallySick,j) ~= 0)
% %                     population.disease(j) = 0;
% %                     population.tau(j) = -1;
% %                 end
% %             end  
%         end 
%     end
    
    % 7) Screening. At given screening time steps t= T_sc, a specified
    % percentage of individuals chosen at random from the subgroup to be
    % screened. From those individuals, s is set to 0.
    
    % is this "subgroup" all infecteds? all asymptomatically infected? or
    % just all people? Say, for all people less than 25, we screen?
    
    
    % INCREMENT AGES WHEN APPROPRIATE
    for i = 1:simulationTime
        if (days == 365*i)
            % a year has passed and therefore we increment all ages
            age = (age + 1);
        end
    end
    
end

for days = 1 : (trackingTime*365) % each time step
    
    % ------For all infected people, a day has gone by so their time since
    % infection, or tau, has increased by a day -------------------------%
    tau = tau + (tau >= 0);
    %---------------------------------------------------------------------%
    
    % 1) Form Partnerships
    % how to find the total number of partnerships 
    inRelationship = find(numPartners~=0);
    partnerships = 0;
    for person = inRelationship
        partnerships = (partnerships + numPartners(person));
    end
    partnerships = (partnerships/2);
    iterations = ( half_population_size - partnerships );
    
    for i=1:iterations
        X = rand; % form a partnership with p = 0.006
        if (X <= 0.006) % partnership will be formed!
            Y = rand; %i) steady with f=0.2 otherwise casual 
            if (Y <= 0.2) % steady relationship: denoted with a 2
                coupleFormed = 0;
                while (coupleFormed == 0)
                    Z = rand;
                    %ii) male y and female x drawn from population
                    female = randi(half_population_size,1);
                    male = randi([half_population_size+1,population_size],1);
                    % Our mixing probability function requires the terms:
                    % extract terms:
                    femaleAge = age(female);
                    femaleSA = sa(female);
                    femaleNumPartners = numPartners(female);
                    maleAge = age(male);
                    maleSA = sa(male);
                    maleNumPartners = numPartners(male);
                    
                    mixing_prob = 0;
                    %iii) form partnership with probability phi(x,y) AS
                    %LONG AS they are not already in a relationship
                    if (relationshipMatrix(female,male) == 0)
                        mixing_prob = mixing_probability_function(femaleAge,...
                            femaleSA,femaleNumPartners,maleAge,maleSA,...
                            maleNumPartners,2);
                    end
                    if (mixing_prob >= Z)
                        % MAKE COUPLE: INDICATE COUPLE (& STEADY) IN
                        % RELATIONSHIP MATRIX
                        relationshipMatrix(female,male) = 2;
                        relationshipMatrix(male,female) = 2;
                        numPartners(female) = (numPartners(female) + 1);
                        numPartners(male) =  (numPartners(male) + 1);
                        coupleFormed = 1;
                    end
                    %iv) if x and y don't form partnership -> repeat ii) 
                    % and iii) until a partnership is formed
                end
            end
            if (Y > 0.2) % we know that a casual relationship is formed
                coupleFormed = 0;
                while (coupleFormed == 0)
                    Z = rand;
                    %ii) male y and female x drawn from population
                    female = randi(half_population_size,1);
                    male = randi([half_population_size+1,population_size],1);
                    % Our mixing probability function requires the terms:
                    % age, sexual activity, number of partners
                    % extract terms:
                    femaleAge = age(female);
                    femaleSA = sa(female);
                    femaleNumPartners = numPartners(female);
                    maleAge = age(male);
                    maleSA = sa(male);
                    maleNumPartners = numPartners(male);
                    
                    mixing_prob = 0;
                    %iii) form partnership with probability phi(x,y) AS
                    %LONG AS not in relationship already
                    if (relationshipMatrix(female,male) == 0)
                        mixing_prob = mixing_probability_function(femaleAge,...
                            femaleSA,femaleNumPartners,maleAge,maleSA,...
                            maleNumPartners,1);
                    end
                    
                    if (mixing_prob >= Z)
                        % MAKE COUPLE: INDICATE COUPLE (& CASUAL) IN
                        % RELATIONSHIP MATRIX
                        relationshipMatrix(female,male) = 1;
                        relationshipMatrix(male,female) = 1;
                        numPartners(female) = (numPartners(female) + 1);
                        numPartners(male) = (numPartners(male) + 1);
                        coupleFormed = 1;
                    end
                    %iv) if x and y don't form partnership -> repeat ii) 
                    % and iii) until a partnership is formed
                end
            end        
        end
    end
    
    % 2) Disease transmission
    % for every couple in which s=0 for one but s=1,2 and tau > incubation
    % for the other, disease- and gender-specific probability of disease
    % transmission NOTE: IN MATRICES: (row,column)
    
    for i = 1:half_population_size %rows: (all females)
        for j = half_population_size+1:population_size; %cols: (all males)
            if (relationshipMatrix(i,j) ~= 0) %in some sort of relationship
                dF = disease(i);
                dM = disease(j);
                rel = relationshipMatrix(i,j);
                tauF = tau(i);
                tauM = tau(j);
                
                diseaseNUM = DISEASE(dF,tauF,dM,tauM,incubation_time_female,...
                    incubation_time_male,rel,T_male2female_steady, ...
                    T_female2male_steady,T_male2female_casual,...
                    T_female2male_casual, asymptomatic_males, ...
                    asymptomatic_females );
                
                if (diseaseNUM ~= 0) % some change happens
                    if (diseaseNUM == 1)
                        disease(i) = 2;
                        tau(i) = 0;
                    elseif (diseaseNUM == 2)
                        disease(i) = 1;
                        tau(i) = 0;
                    elseif (diseaseNUM == 3)
                        disease(j) = 2;
                        tau(j) = 0;
                    elseif(diseaseNUM == 4)
                        disease(j) = 1;
                        tau(j) = 0;
                    end
                end
            end
        end
    end

    
    % 3) Separation of partnerships
    % with probability 0.0004 steady partnerships break
    % with probability 0.1 casual partnerships break
    
    for i = 1:half_population_size %rows: females!
        for j = half_population_size+1:population_size; %cols: males!
            if (relationshipMatrix(i,j) ~= 0) %in some sort of relationship
                rr = rand;
                if (relationshipMatrix(i,j) == 1) % in casual relationship
                     if (rr <= 0.1)
                         % i and j break up
                         % separation causes N -> N\{name of partner}
                         relationshipMatrix(i,j) = 0;
                         relationshipMatrix(j,i) = 0;
                         % number of relationships each partner has
                         % decreases by 1
                         % separation causes d -> d-1
                         numPartners(i) = (numPartners(i) - 1);
                         numPartners(j) = (numPartners(j) - 1);
                     end
                elseif (relationshipMatrix(i,j) == 2) % in steady relationship
                     if (rr <= 0.0004)
                         relationshipMatrix(i,j) = 0;
                         relationshipMatrix(j,i) = 0;

                         numPartners(i) = (numPartners(i) - 1);
                         numPartners(j) = (numPartners(j) - 1);
                     end
                end
            end
        end
    end
    
    % 4) Replacement (NOTE WHEN I INCREMENT AGES)
    % all 65y.o. replaced with 15 year old of same name, gender, but for
    % this replacement a=15, c=c', s=0, tau=-1, d=0 and N= empty set
    % c' denotes new activity status
    old = find(age == 65);
    for i=old
        age(i) = 15;
        disease(i) = 0;
        tau(i) = -1;
        numPartners(i) = 0;
        sa(i) = 0;
        rr =  rand;
        if (rr <= 0.05)
            sa(i) = 1;
        end
        
        %NEED TO REMOVE RELATIONSHIPS INVOLVING THIS 65 YEAR OLD IN
        %RELATIONSHIP MATRIX AND NUM PARTNERS OF EVERYONE INVOLVED
        for partner=1:population_size
            % IF there is relationship between an individual and i
            % then we need to break that off 
            if (relationshipMatrix(partner,i) ~= 0)
                % relationship exists --> END IT
                relationshipMatrix(partner,i) = 0;
                relationshipMatrix(i,partner) = 0;

                numPartners(partner) = (numPartners(partner) - 1);
            end
        end 
    end
    
    % 5) Recovery
    % transition from s=1 or s=2 to s=0 with disease- and gender-specific
    % probabilities
    
    sick = find(disease ~= 0 );
    for i = sick
        if (sex(i) == 0)
            % person is female
            rr =rand;
            if ((disease(i) == 1) && (rr <= recovery_symp_female))
                % symptomatically infected & recovers
                disease(i) = 0;
                tau(i) = -1;
            elseif ( (disease(i) == 2) && (rr <= recovery_asymp_female))
                % assymptomatically infected & recovers
                disease(i) = 0;
                tau(i) = -1;
            end
        elseif (sex(i) == 1)
            % person is male
            rr =rand;
            if ((disease(i) == 1) && (rr <= recovery_symp_male))
                % symptomatically infected & recovers
                disease(i) = 0;
                tau(i) = -1;
            elseif ((disease(i) == 2) && (rr <= recovery_asymp_male))
                % assymptomatically infected & recovers
                disease(i) = 0;
                tau(i) = -1;
            end
        end 
    end
    
    % 6) Treatment (and contact tracing). Transition of symptomatically
    % infecteds (s=1) with tau = incubation time and patient delay to s=0
    % with probability 1 (treatment is 100% effective). Contact tracing: at
    % treatment of symptomatically infected, all partners in N also return
    % disease status s=0. 
%     symptomaticallySick = find(population.disease == 1 );
%     maleTime = delayANDtreatment_male + incubation_time_male;
%     femaleTime = delayANDtreatment_female + incubation_time_female;
%     for i = symptomaticallySick
%         if ( (population.sex(i) == 0) && (population.tau(i) >= femaleTime))
%             % female and partners get treated
%             population.disease(i) = 0;
%             population.tau(i) = -1;
% %             for j = 1:population_size
% %                 if (relationshipMatrix(symptomaticallySick,j) ~= 0)
% %                     population.disease(j) = 0;
% %                     population.tau(j) = -1;
% %                 end
% %             end    
%         elseif ( (population.sex(i) == 1) && (population.tau(i) >= maleTime))
%             % male and partners get treated
%             population.disease(i) = 0;
%             population.tau(i) = -1;
% %             for j = 1:population_size
% %                 if (relationshipMatrix(symptomaticallySick,j) ~= 0)
% %                     population.disease(j) = 0;
% %                     population.tau(j) = -1;
% %                 end
% %             end  
%         end 
%     end
    
    % 7) Screening. At given screening time steps t= T_sc, a specified
    % percentage of individuals chosen at random from the subgroup to be
    % screened. From those individuals, s is set to 0.
    
    % is this "subgroup" all infecteds? all asymptomatically infected? or
    % just all people? Say, for all people less than 25, we screen?
    
    
    % INCREMENT AGES WHEN APPROPRIATE
    for i = 1:trackingTime
        if (days == 365*i)
            % a year has passed and therefore we increment all ages
            age = (age + 1);
        end
    end
    

 diseased = find(disease ~= 0);
 AmenNum = 0;
 SmenNum = 0;
 AwomenNum = 0;
 SwomenNum = 0;
 for sicko = diseased
        if (disease(sicko) == 2) %assymp
            if (sex(sicko) == 1) %male
                AmenNum = AmenNum+1;
            else %female
                AwomenNum = AwomenNum+1;
            end
        else %(population.disease(sickPerson) == 1) %symp
            if (sex(sicko) == 1) %male
                SmenNum = SmenNum+1;
            else %female
                SwomenNum = SwomenNum+1; 
            end
        end
 end
 Amen(days) = AmenNum;
 Smen(days) = SmenNum;
 Awomen(days) = AwomenNum;
 Swomen(days) = SwomenNum;  

end
%-Average Disease:--------------------------------------------------------%
%-Keep #s in Population and write to file--------------------------------%
mean_A_infected_men = mean(Amen)
mean_S_infected_men = mean(Smen)
mean_A_infected_women = mean(Awomen)
mean_S_infected_women = mean(Swomen)

filename = '10percentSA_CC.mat';
save(filename,'mean_A_infected_men','mean_S_infected_men',...
     'mean_A_infected_women','mean_S_infected_women');





