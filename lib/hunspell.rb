##
# KISS + Hunspell (Keep It Simple but no Simpler) 
# => Hunspell binding within 60 lines (thanks to RubyInline :)
#
# Nguyen Tien Dung (dungtn@gmail.com)

require 'rubygems'
require 'inline'

class Hunspell
  inline do |builder|
    builder.add_link_flags("-lhunspell-1.2")
    
    builder.prefix <<-EOC
      typedef struct Hunhandle Hunhandle;
      Hunhandle *Hunspell_create(const char * affpath, const char * dpath);
      void Hunspell_destroy(Hunhandle *pHunspell);

      int Hunspell_spell(Hunhandle *pHunspell, const char *);
      int Hunspell_suggest(Hunhandle *pHunspell, char*** slst, const char * word);
    EOC
    
    builder.c_singleton <<-EOC
      VALUE new(const char* affpath, const char* dpath) {
        Hunhandle *pHunspell;
        pHunspell = Hunspell_create(affpath, dpath);

        if (!pHunspell) {
          rb_raise(rb_eRuntimeError, "Failed to initialize Hunspell.");
        }    

        return Data_Wrap_Struct(self, 0, Hunspell_destroy, pHunspell);
      }
    EOC

    builder.c <<-EOC
      VALUE check(const char* str) {
        Hunhandle *pHunspell;
        Data_Get_Struct(self, Hunhandle, pHunspell);

        return (Hunspell_spell(pHunspell, str) == 1 ? Qtrue : Qfalse);
      }
    EOC

    builder.c <<-EOC
      VALUE suggest(const char* str) {
        int i, n;
        char **list, *item;
        VALUE suggestions;

        Hunhandle *pHunspell;
        Data_Get_Struct(self, Hunhandle, pHunspell);
        
        n = Hunspell_suggest(pHunspell, &list, str);
        suggestions = rb_ary_new2(n);
        
        for (i = 0; i < n; i++) {
          item = list[i];
          rb_ary_push(suggestions, rb_str_new2(item));
          free(item);
        }

        if (n > 0) { 
          free(list); 
        }

        return suggestions;
      }
    EOC
  end
end