function value = KbName(name)
 switch name
     case 'UnifyKeyNames'
         value = [];
     case '5%'
         value = 7;
     case 'space'
         value = 8;
     otherwise
         error('Part2bTest:UnknownKey', 'Unexpected key name.');
 end
end
