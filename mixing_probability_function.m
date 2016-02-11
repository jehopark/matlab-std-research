function Y = mixing_probability_function( fA,fSA,fNUM,mA,mSA,mNUM,i )
% Two individuals, x & y, form a partnership with probability phi(x,y)
% Assume that x is defined by state vector (x,f,a_x,c_x,s_x,tau_x,d_x,N_x)
% and y by (y,m,a_y,c_y,s_y,tau_y,d_y,N_y).
if (fNUM <= 4 && mNUM <= 4)
    % i is the relationship type (i.e. steady or casual)

    % age classes:
    % 1 = 15-24
    % 2 = 25-34
    % 3 = 35-44
    % 4 = 45-54
    % 5 = 55-64

    % Let's assume we have an x and an y and we extract the parameters

    % We define
    %        phi^i(x,y) = phi^i_a(j,k) phi^i_(cd) (c_x,c_y,d_x,d_y)
    % where i=1,2 and refers to relationship type (2 for steady, 1 for casual)
    % j,k = 1,...,5 refer to the female's and male's age class, respectively

    %Let's first  get j & k
    if (fA <= 24)
        j = 1;
    elseif (fA >= 25 && fA <= 34)
        j = 2;
    elseif (fA >= 35 && fA <= 44)
        j = 3;
    elseif (fA >= 45 && fA <= 54)
        j = 4;
    else % we know (fA >= 55)
        j = 5;
    end

    if (mA <= 24)
        k = 1;
    elseif (mA >= 25 && mA <= 34)
        k = 2;
    elseif (mA >= 35 && mA <= 44)
        k = 3;
    elseif (mA >= 45 && mA <= 54)
        k = 4;
    else % we know (mA >= 55)
        k = 5;
    end

    % For i = 1,2:
    %           we take phi^i_a(j,k) = 1 for j=k
    %           and phi^i_a(j,k) = 0.2^|j+1-k| for j != k
    if (j==k)
        phi_jk = 1;
    else % we know (j ~= k)
        phi_jk = 0.2^abs(j+1-k);
    end


    % We define phi^2_(cd) (c_x,c_y,d_x,d_y) = 1 if d_x = 0 and d_y = 0, 0
    % otherwise
    if (i == 2) %STEADY
        if ( fNUM == 0 && mNUM == 0)
            phi_cd = 1;
        else
            phi_cd = 0;
        end
    
    % We define phi^1_(cd) (c_x,c_y,d_x,d_y)
    %                                   = 1 if c_x = c_y = 1
    %                                   = 0.1 if c_x = 1 & c_y = d_y = 0
    %                                   = 0.1 if c_y = 1 & c_x = d_x = 0
    %                                   = 0.01 if c_x = c_y = d_x = d_y = 0
    %                                   = 0 otherwise
    else % we know (i ==1) or that it is casual CASUAL
        if ((fSA == 1) && (mSA == 1))
            phi_cd = 1;
        elseif ((fSA == 1) && (mSA == 0) && (mNUM == 0))
            phi_cd = 0.1;
        elseif ((mSA == 1) && (fSA == 0) && (fNUM == 0))
            phi_cd = 0.1;
        elseif ((fSA == 0) && (mSA == 0) && (fNUM == 0) && (mNUM == 0))
            phi_cd = 0.01;
        else
            phi_cd = 0;
        end
    end

    % phi^i(x,y) = phi^i_a(j,k) phi^i_(cd) (c_x,c_y,d_x,d_y)
    % we are returning Y as the  mixing probability therefore we find
    Y = phi_jk * phi_cd;
else
    Y = 0;
end
end

