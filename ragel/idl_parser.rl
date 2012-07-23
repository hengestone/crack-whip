// Copyright 2012 Conrad Steenberg <conrad.steenberg@gmail.com>
// 7/17/2012

import crack.cont.hashmap OrderedHashMap;
import crack.cont.list List;
import crack.cont.array Array;
import crack.io FStr, cout, cerr, Reader;
import crack.lang AppendBuffer, InvalidResourceError, Buffer, Formatter,
                  Exception, IndexError, CString;
import crack.runtime memmove, mmap, munmap, Stat, fopen, PROT_READ, MAP_PRIVATE,
                    stat, fileno;
import crack.sys strerror;
import crack.math min;
import crack.io.readers PageBufferString, PageBufferReader, PageBuffer;
import whip.utils.generator Message, ClassGenerator;

uint indentWidth = 2;

class ParseError : Exception {
    oper init(String text) : Exception(text) {}
    oper init() {}
}

class idlParser {

    ClassGenerator gen;
    PageBuffer data;
    OrderedHashMap[String, bool] filesDone = {};
    List[String] filesTodo = {};
    uint data_size = 0, eof = 0, s, e, p, pe, cs, ts, te, act, okp, bufsize = 1024*1024;
    int line = 1, col = 1;

    void _readTo(uint i){
        if (i>data.size){
            try {
                b:=data[i];
            }
            catch (IndexError ex){
            }
            pe = data.size;
        }
    }

    %%{
        machine spec;

        action buffer { _readTo(p); s = p; }
        action nameStart {
          cout `NameStart: '$(data.substr(s, e - s))'\n`;
          s = e = p;
        }
        action messageName {
          if (curMsgName is null) {
            e = p;
            curMsgName = data.substr(s, e - s);
            cout `curMsgName = $curMsgName\n`;
            curMsg = Message();
          }
          else {
            cout `curMsgName already set\n`;
          }
        }

        action fieldType {
          e = p;
          curFieldType = data.substr(s, e - s);
          cout `curFieldType = $curFieldType\n`;
          curFieldName = null;
          curFieldDefault = null;
          foundEq = false;
          fieldAdded = false;
        }

        action fieldName {
          if (curFieldName is null) {
            e = p;
            curFieldName = data.substr(s, e - s);
            cout `curFieldName = $curFieldName\n`;
          }
        }

        action foundEq {
          foundEq = true;
        }

        action defaultVal {
          e = p;
          curFieldDefault = data.substr(s, e - s);
          cout `curFieldDefault = $curFieldDefault\n`;
        }

        action fieldEnd {
          if (curFieldName is null) { // We got a field name followed by a ;
            e = p;
            curFieldName = data.substr(s, e - s);
            cout `curFieldName = $curFieldName\n`;
          } else if (foundEq && (curFieldDefault is null)) { // Got = .. ;
            e = p;
            curFieldDefault = data.substr(s, e - s);
            cout `curFieldDefault = $curFieldDefault\n`;
          }

          if (!fieldAdded) {
            curMsg.addField(curFieldName, curFieldType, curFieldDefault);
            fieldAdded = true;
          }
        }

        action messageEnd {
          cout `messageEnd\n`;
          gen.addMessage(curMsgName, curMsg);
          curMsgName = null;
        }

        action fileEnd {
          e = p;
          if (true) {
            incFileName := data.substr(s, e - s);
            cout `incfileName = $incFileName\n`;
          }
        }

        eol = [\r\n]+;
        varAlpha = [a-zA-Z_];
        varAlphaNum = [a-zA-Z_0-9\-]+;
        typeAlphaNum = [a-zA-Z_0-9\-\[\]]+;
        valueAlphaNumStart = [0-9\-\.\[\'\"\{];
        valueAlphaNumEnd = [0-9\-\.\]\'\"\}];
        varName = varAlpha varAlphaNum*;
        varType =varAlpha typeAlphaNum*;

        field = varType >nameStart space+ >fieldType
                varName >nameStart (space* >fieldName)
                ('=' >fieldName >foundEq space*
                valueAlphaNumStart >nameStart [^;]*
                space* >defaultVal)? ';' >fieldEnd;

        message = 'message' space+ varName >nameStart (space* >messageName)
                 '{' >messageName
                  (space* field)* space*
                 '}' >messageEnd;
        importfile = 'import' space+ '"' 
                  [^\"]+ >nameStart '"' >fileEnd space* ';';

        main := (space+ | importfile | message)+;

    }%%

    %% write data;

    void reset(){
        p = s = 0;

        %% write init;
    }

    oper init (ClassGenerator gen0) : gen = gen0 { }

    int _parse() {    // Do the first read. 
        if (data is null)
            InvalidResourceError(FStr() `Error parsing IDL, null data pointer supplied`);
        uint parseLoops = 0;
        String curMsgName, curFieldName, curFieldType, curFieldDefault;
        Message curMsg;
        bool foundEq = false, fieldAdded = false;

        pe = data_size;
        cs = spec_start;
        while (parseLoops <2 && p < pe){
        // ------ Start exec ---------------------------------------------------------
        %% write exec;
        // ------ End exec -----------------------------------------------------------
            _readTo(pe+1); // Update pe just in case we got stuck at the end of a page by accident
            if (p < pe ) parseLoops++;
        }

        /* Check if we failed. */
        if ( cs == spec_error ) {
            /* Machine failed before finding a token. */
            throw ParseError(data.substr(s, p - s));
        }

        if (p < pe) {
            uint lineNumber = 1;
            for (uint i = 0; i < p; i++)
                if (data[i] == b'\n') lineNumber++;
            throw InvalidResourceError(FStr() `Error parsing IDL on line $lineNumber near: $(data.substr(p, min(32, pe-p)))`);
        }

        return gen.messages.count();
    }

    int parse(String spec) {
        data = PageBufferString(spec);
        data_size = spec.size;
        return _parse();
    }

    int parse(Reader r) {
        data = PageBufferReader(r); // Reads one block
        data_size = data.size; 
        return _parse();
    }

    int parseFile(String fname) {
        Stat statInfo = {};
        n := CString(fname);
        statErrors := stat(n.buffer, statInfo);
        if (!statErrors){
            mode := "r";
            file := fopen(n.buffer, mode.buffer);

            if (file is null) {
                throw InvalidResourceError(FStr() `$fname: $(strerror())`);
            }
            fd := fileno(file);

            data_size = statInfo.st_size;
            tdata := mmap(null, statInfo.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
            data = PageBufferString(String(byteptr(tdata), data_size, false));
            
            if (uintz(tdata) != uintz(0)-1){
                retval := _parse();
                munmap(tdata, data_size);
                return retval;
            }
            else
                throw InvalidResourceError(FStr() `$fname: $(strerror())`);
        }
        return 0;
    }

    void formatTo(Formatter fmt){
      fmt.format(gen);
    }
}
