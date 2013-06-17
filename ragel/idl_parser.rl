// Copyright 2012 Conrad Steenberg <conrad.steenberg@gmail.com>
// 7/17/2012

import crack.cont.hashmap OrderedHashMap;
import crack.strutil StringArray, split;
import crack.cont.list List;
import crack.cont.array Array;
import crack.io FStr, cout, cerr, Reader;
import crack.lang AppendBuffer, InvalidResourceError, Buffer, Formatter,
                  Exception, IndexError, CString;
import crack.runtime memmove, mmap, munmap, Stat, fopen, PROT_READ, MAP_PRIVATE,
                    stat, fileno, free, CFile;
import crack.sys strerror;
import crack.math min;
import crack.io.readers PageBufferString, PageBufferReader, PageBuffer;
import whip.utils.generator Message, ClassGenerator;
import crack.logger Logger, DEBUG, FATAL, ERROR, INFO;

sfmt := FStr(); // string formatter
uint indentWidth = 2;

class ParseError : Exception {
    oper init(String text) : Exception(text) {}
    oper init() {}
}

class _fileInfo {
    Stat info;
    CString name;
    oper init(Stat si, CString fname) : name=fname, info=si { }

    oper del() {
        if (!(info is null)) free(info);
    }
}

@abstract class idlParserBase {
    ClassGenerator gen;
    PageBuffer data;
    OrderedHashMap[String, bool] filesDone = {};
    OrderedHashMap[String, bool] pathMap = {};
    List[String] filesTodo = {};
    StringArray paths = ["."];
    uint data_size = 0, eof = 0, s, e, p, pe, cs, ts, te, act, okp, bufsize = 1024*1024;
    int line = 1, col = 1;

    Logger logger;

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

    _fileInfo _findFile(String fname) {
        Stat statInfo = {};
        _fileInfo fi = {statInfo, null};
        for (dir :in paths) {
            tryFname := FStr() `$dir/$fname`;
            logger.debug(sfmt `Trying $tryFname`);
            n := CString(tryFname);
            statErrors := stat(n.buffer, statInfo);
            if (!statErrors) {
                fi.name = n;
                return fi;
            }
        }
        throw InvalidResourceError(FStr() `Could not find file $fname in path $(paths.join(":"))`);
    }

    uint addPath(String path) {
        newPath := split(path, ":");
        if (newPath) paths.extend(newPath);
        return paths.count();
    }

    uint setPath(String path) {
        newPath := split(path, ":");
        if (newPath) paths = newPath;
        else
            throw InvalidResourceError(FStr() `Could not determine path array from $(path)`);
        return paths.count();
    }

    uint setPath(StringArray newPath) {
        if (newPath) paths = newPath;
        else
            throw InvalidResourceError(FStr() `Could not determine path array from $(newPath.join(":"))`);
        return paths.count();
    }

    uint __countBytes(Array[String] A) {
        uint total;
        for (elem :in A)
            total += elem.size;
        return total;
    }


    // Taken from strutil.StringArray.join
    String _join(Array[String] A, String sep) {
        # deal with the empty case
        size := A.count();
        if (!size)
            return '';
        
        # figure out how much space we need
        total := __countBytes(A) + sep.size * (size - 1);
        
        AppendBuffer buf = {total};
        first := true;
        for (elem :in A) {
        
            # add the separator for everything but the first string.
            if (first)
                first = false;
            else
                buf.extend(sep);

            buf.extend(elem);
        }
        
        return String(buf, true);

    }

    void updatePathFromFile(String fname) {
        newPath := _join(split(fname, "/").slice(0,-1), "/");
        if (!pathMap.get(newPath)) {
            addPath(newPath);
            pathMap[newPath] = true;
            logger.debug(sfmt `updatePathFromFile($fname): newPath=$newPath`);
        }
        
    }

    @abstract int _parse();
    @abstract int parse(String spec);
    @abstract int parseTodo();
    @abstract int parseFile(String fname_in);

    void formatTo(Formatter fmt) {
      fmt.format(gen);
    }
}

class idlParser : idlParserBase {


    %%{
        machine spec;

        action buffer { _readTo(p); s = p; }

        action nameStart {
          s = e = p;
        }

        action readonly {
            readOnly = true;
        }

        action newLine {
            line++;
        }

        action messageName {
          if (curMsgName is null) {
            e = p;
            curMsgName = data.substr(s, e - s);
            curMsg = Message();
          }
        }

        action fieldType {
          e = p;
          curFieldType = data.substr(s, e - s);
          curFieldName = null;
          curFieldDefault = null;
          foundEq = false;
          fieldAdded = false;
        }

        action fieldName {
          if (curFieldName is null) {
            e = p;
            curFieldName = data.substr(s, e - s);
          }
        }

        action foundEq {
          foundEq = true;
        }

        action defaultVal {
          e = p;
          curFieldDefault = data.substr(s, e - s);
        }

        action fieldEnd {
          if (curFieldName is null) { // We got a field name followed by a ;
            e = p;
            curFieldName = data.substr(s, e - s);
          } else if (foundEq && (curFieldDefault is null)) { // Got = .. ;
            e = p;
            curFieldDefault = data.substr(s, e - s);
          }

          if (!fieldAdded) {
            curMsg.addField(curFieldName, curFieldType, curFieldDefault);
            fieldAdded = true;
          }
          readOnly = false;
        }

        action messageEnd {
          gen.addMessage(curMsgName, curMsg);
          curMsgName = null;
        }

        action fileEnd {
          e = p;
          if (true) {
            incFileName := data.substr(s, e - s);
            logger.debug(sfmt `Parsing file $incFileName`);
            _parser := idlParser(gen); // new parser object
            _parser.setPath(paths);
            _parser.parseFile(incFileName);
            filesDone[incFileName] = true;
            for (item :in _parser.filesDone) {
                filesDone[item.key] = true;
            }
          }
        }

        eol = [\r\n];
        spc = [ \t];
        sep = (spc* eol? >newLine spc+);
        varAlpha = [a-zA-Z_];
        varAlphaNum = [a-zA-Z_0-9\-]+;
        typeAlphaNum = [a-zA-Z_0-9\-\[\]]+;
        valueAlphaNumStart = [0-9\-\.\[\'\"\{];
        valueAlphaNumEnd = [0-9\-\.\]\'\"\}];
        varName = varAlpha varAlphaNum*;
        varType =varAlpha typeAlphaNum*;

        field = ('@readonly'? >readonly) space+ varType
                >nameStart space+ >fieldType
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

    oper init (ClassGenerator gen0) {
        gen = gen0;
        logger = Logger(cerr, INFO);
    }

    int _parse() {    // Do the first read. 
        if (data is null)
            InvalidResourceError(FStr() `Error parsing IDL, null data pointer supplied`);
        uint parseLoops = 0;
        String curMsgName, curFieldName, curFieldType, curFieldDefault;
        Message curMsg;
        bool foundEq = false, fieldAdded = false, readOnly = false;

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
            throw ParseError(sfmt `Syntax error on line $line:$col, near $(data.substr(s, p - s))`);
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

    int parseTodo() {
        int numMessages = 0;
        while (filesTodo) {
            fname := filesTodo.popHead();
            iFile := _findFile(fname); // IDL file description
            updatePathFromFile(iFile.name);
            cFile := fopen(iFile.name.buffer, "r".buffer); // C File struct
            
            fd := fileno(cFile);

            data_size = iFile.info.st_size;
            tdata := mmap(null, iFile.info.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
            data = PageBufferString(String(byteptr(tdata), data_size, false));
            
            if (uintz(tdata) != uintz(0) - 1) {
                retval := _parse(); // This might add filenames to filesTodo
                munmap(tdata, data_size);
                numMessages += retval;
                filesDone[fname] = true;
            }
        }
        return numMessages;
    }

    int parseFile(String fname_in) {
        filesTodo.append(fname_in);
        return parseTodo();
    }

    int parse(Reader r) {
        int numMessages = 0;
        data = PageBufferReader(r); // Reads one block
        data_size = data.size; 
        numMessages += _parse();
        return numMessages + parseTodo();
    }
}
