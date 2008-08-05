require 'rubygems'
require 'inline'

class Hunspell
  inline do |builder|
    builder.add_link_flags("-lhunspell-1.2")
    
    builder.prefix <<-HUNSPELL_H
      typedef struct Hunhandle Hunhandle;
      Hunhandle *Hunspell_create  (const char *affpath, const char *dicpath);
            void Hunspell_destroy (Hunhandle *pHunspell);
             int Hunspell_spell   (Hunhandle *pHunspell, const char *word);
             int Hunspell_suggest (Hunhandle *pHunspell, char ***slst, const char *word);
    HUNSPELL_H
    
    builder.prefix <<-GET_HUNHANDLE
      static Hunhandle *get_hunhandle(VALUE klass) {
        Hunhandle *pHunspell;
        Data_Get_Struct(klass, Hunhandle, pHunspell);
        if (pHunspell == NULL) {
          rb_raise(rb_eRuntimeError, "Something wrong with wrapped Hunspell handle.");
        }
        return pHunspell;
      }
    GET_HUNHANDLE
    
    builder.c_singleton <<-HUNSPELL_NEW
      VALUE new(const char* affpath, const char* dicpath) {
        Hunhandle *pHunspell = Hunspell_create(affpath, dicpath);
        if (pHunspell == NULL) {
          rb_raise(rb_eRuntimeError, "Failed to initialize Hunspell.");
        }
        return Data_Wrap_Struct(self, 0, Hunspell_destroy, pHunspell);
      }
    HUNSPELL_NEW

    builder.c <<-HUNSPELL_CHECK
      VALUE check(const char* str) {
        return (Hunspell_spell(get_hunhandle(self), str) == 1 ? Qtrue : Qfalse);
      }
    HUNSPELL_CHECK

    builder.c <<-HUNSPELL_SUGGEST
      VALUE suggest(const char* word) {
        int i, n;
        char **list, *item;
        VALUE suggestions;

        n = Hunspell_suggest(get_hunhandle(self), &list, word);
        suggestions = rb_ary_new2(n);
        
        for (i = 0; i < n; ++i) {
          item = list[i];
          rb_ary_push(suggestions, rb_str_new2(item));
          free(item);
        }

        if (n > 0) {
          free(list); 
        }
        
        return suggestions;
      }
    HUNSPELL_SUGGEST
  end
end